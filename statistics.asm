        # External devices:
	asect 0xF6
scores_counter: 
	current_score : ds 1
	record_score : ds 1

	asect 0xF8
lives_counter:
	number_of_remaining_lives : ds 1
	number_of_saved_frogs : ds 1

		# Interrupts:
	asect 0xF0
bump : dc bump_ISR                  # the current score - 10,
bump_flags_combo : dc 0x00          # the number of remaining lives - 1;

rescue : dc rescue_ISR              # the current score + 16,
rescue_flags_combo : dc 0x00        # the number of saved frogs + 1;
	
good_jump : dc good_jump_ISR        # the current score + 1.
good_jump_flags_combo : dc 0x00

        # Routines: 
	asect 0x00
start_game:
	ei                        # enabling the interrupts
	ldi r0, number_of_remaining_lives
	ldi r1, 3                 # there are 3 lives at the beginning of the game
	st r0, r1                 # initializing the number of remaining lives
	br check_for_interrupts
	
    # Checks:
check_for_interrupts:
	if
		ldi r0, bump_flags_combo
		ld r0, r1
		tst r1
	is z                      
		if                    # the bump_interrupt has not occurred yet
			ldi r0, rescue_flags_combo
			ld r0, r1
			tst r1
		is z                  
			if                # and the rescue_interrupt has not occurred yet
				ldi r0, good_jump_flags_combo
				ld r0, r1
				tst r1
			is z           
				wait          # and the good_jump_interrupt has not occurred yet
				br check_for_interrupts
			else              # the good_jump_interrupt has already occurred
				jsr update_current_score
				jsr update_record_score	
				clr r1        # clearing the good_jump_flags_combo
				ldi r0, good_jump_flags_combo
				st r0, r1
				br check_for_interrupts
			fi
		else                  # the rescue_interrupt has already occurred
			ld r0, r0
			while
				dec r0
			stays ge
				ldi r1, 16        # adding 16 points
				jsr update_current_score
			wend
			jsr update_record_score
			jsr update_frog_survivors
			clr r1            # clearing the rescue_flags_combo
			ldi r0, rescue_flags_combo
			st r0, r1
			br check_number_of_survivors
		fi
	else                      # the bump_interrupt has already occurred
		ld r0, r0
		while
			dec r0
		stays ge
			ldi r1, -10           # removing 10 points
			jsr update_current_score
		wend
		jsr update_record_score
		jsr update_frog_lives
		clr r1                # clearing the bump_flags_combo
		ldi r0, bump_flags_combo
		st r0, r1
		br check_number_of_hearts
	fi
	
check_number_of_hearts:
	ldi r0, number_of_remaining_lives
	ld r0, r1
	if
		tst r1
	is eq                       # the game is lost
		di                      # disabling interrupts
		halt                  
	else
		br check_for_interrupts # continuation
	fi
	
check_number_of_survivors:
	ldi r0, number_of_saved_frogs 
	ld r0, r1
	ldi r0, 4
	if
		cmp r1, r0
	is eq                       # the game is won
		di                      # disabling interrupts
		halt
	else
		br check_for_interrupts # continuation
	fi

    # Updates:
update_current_score:         # r1 must contain the number of points to be added
	ldi r0, current_score
	ld r0, r0
	if
		add r0, r1
	is lt                     # if the current score becomes negative,
		clr r1                # then it becomes zero
		ldi r0, current_score
		st r0, r1
	else
		ldi r0, current_score
		st r0, r1
	fi
	rts
	
update_record_score:          # r1 must contain the current score
	ldi r0, record_score
	ld r0, r0
	if
		cmp r0, r1
	is lt                     # if the record score is less than the current one,
		ldi r0, record_score  # then the record score is updated
		st r0, r1
	fi
	rts

update_frog_lives:
	ldi r1, bump_flags_combo
	ld r1, r1
	ldi r0, number_of_remaining_lives
	ld r0, r0
	if
		sub r0, r1
	is lt                     # if the number of remaining lives becomes negative,
		clr r1                # then it becomes zero
		ldi r0, number_of_remaining_lives
		st r0, r1
	else
		ldi r0, number_of_remaining_lives
		st r0, r1
	fi       
	rts
	
update_frog_survivors:
	ldi r1, rescue_flags_combo
	ld r1, r1
	ldi r0, number_of_saved_frogs 
	ld r0, r0
	add r0, r1                # increasing the number of saved frogs 
	ldi r0, number_of_saved_frogs 
	st r0, r1
	rts
	
    # Interrupt Service Routines:
bump_ISR:
	ldi r2, bump_flags_combo
	ld r2, r3
	inc r3                    # increasing the combination of bump_flags
	st r2, r3
	rti
	
rescue_ISR:
	ldi r2, rescue_flags_combo
	ld r2, r3
	inc r3                    # increasing the combination of rescue_flags
	st r2, r3
	rti
	
good_jump_ISR:
	ldi r2, good_jump_flags_combo
	ld r2, r3
	inc r3                    # increasing the combination of good_jump_flags
	st r2, r3
	rti

end
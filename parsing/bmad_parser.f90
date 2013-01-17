!+
! Subroutine bmad_parser (lat_file, lat, make_mats6, digested_read_ok, use_line, err_flag)
!
! Subroutine to parse a BMAD input file and put the information in lat.
!
! Because of the time it takes to parse a file bmad_parser will save 
! LAT in a "digested" file with the name:
!               'digested_' // lat_file   
! For subsequent calls to the same lat_file, BMAD_PARSER will just read in the
! digested file. bmad_parser will always check to see that the digested file
! is up-to-date and if not the digested file will not be used.
!
! Modules needed:
!   use bmad
!
! Input:
!   lat_file   -- Character(*): Name of the input file.
!   make_mats6 -- Logical, optional: Compute the 6x6 transport matrices for the
!                   Elements and do other bookkeeping like calculate the reference energy? 
!                   Default is True.
!   use_line   -- Character(*), optional: If present and not blank, override the use 
!                   statement in the lattice file and use use_line instead.
!
! Output:
!   lat              -- lat_struct: Lat structure. See bmad_struct.f90 for more details.
!     %ele(:)%mat6      -- This is computed assuming an on-axis orbit 
!     %ele(:)%s         -- This is also computed.
!   digested_read_ok -- Logical, optional: Set True if the digested file was
!                        successfully read. False otherwise.
!   err_flag         -- Logical, optional: Set true if there is an error, false otherwise.
!                         Note: err_flag does *not* include errors in lat_make_mat6 since
!                         if there is a match element, there is an error raised since
!                         the Twiss parameters have not been set but this is expected. 
!-

subroutine bmad_parser (lat_file, lat, make_mats6, digested_read_ok, use_line, err_flag)

use bmad_parser_mod, except_dummy => bmad_parser
use ptc_interface_mod, dummy2 => bmad_parser
use random_mod

implicit none

type (lat_struct), target :: lat, in_lat, old_lat, lat2
type (ele_struct) this_ele
type (ele_struct), pointer :: ele, slave, lord, ele2, ele0
type (ele_struct), save :: marker_ele
type (seq_struct), target :: sequence(1000)
type (branch_struct), pointer :: branch0, branch
type (parser_lat_struct), target :: plat
type (parser_ele_struct), pointer :: pele
type (lat_ele_loc_struct) m_slaves(100)
type (ele_pointer_struct), allocatable :: branch_ele(:)

integer, allocatable :: seq_indexx(:), in_indexx(:)

integer ix_word, i_use, i, j, k, k2, n, ix, ix1, ix2, n_wall, n_track
integer n_ele_use, digested_version, key, loop_counter, n_ic, n_con
integer  iseq_tot, iyy, n_ele_max, n_multi, n0, n_ele, ixc
integer ib, ie, ib2, ie2, flip, n_branch, n_branch_ele, i_loop, n_branch_max
integer, pointer :: n_max, n_ptr

character(*) lat_file
character(*), optional :: use_line

character(1) delim
character(16), parameter :: r_name = 'bmad_parser'
character(40) word_2, name
character(40) this_name, word_1
character(40), allocatable ::  in_name(:), seq_name(:)
character(80) debug_line
character(200) full_lat_file_name, digested_file, call_file
character(280) parse_line_save, line, use_line_str

logical, optional :: make_mats6, digested_read_ok, err_flag
logical delim_found, arg_list_found, xsif_called, wild_here
logical end_of_file, ele_found, match_found, err_if_not_found, err, finished, exit_on_error
logical detected_expand_lattice_cmd, multipass, wild_and_key0
logical auto_bookkeeper_saved, is_photon_branch, created_new_branch

! see if digested file is open and current. If so read in and return.
! Note: The name of the digested file depends upon the real precision.

auto_bookkeeper_saved = bmad_com%auto_bookkeeper
bmad_com%auto_bookkeeper = .true.  

if (present(err_flag)) err_flag = .true.
bp_com%error_flag = .false.              ! set to true on an error
bp_com%parser_name = 'bmad_parser'       ! Used for error messages.
bp_com%write_digested = .true.
bp_com%do_superimpose = .true.
bp_com%input_from_file = .true.
debug_line = ''

call form_digested_bmad_file_name (lat_file, digested_file, full_lat_file_name)
call read_digested_bmad_file (digested_file, lat, digested_version, err_flag = err)

! Must make sure that if use_line is present the digested file has used the 
! correct line

if (present(use_line)) then
  if (use_line /= '') then
    call str_upcase (name, use_line)
    if (name /= lat%use_name) err = .true.
  endif
endif

if (.not. err .and. .not. bp_com%always_parse) then
  call set_taylor_order (lat%input_taylor_order, .false.)
  call set_ptc (1.0e9_rp, lat%param%particle)  ! Energy value used does not matter here
  if (lat%input_taylor_order == bmad_com%taylor_order) then
    if (present(digested_read_ok)) digested_read_ok = .true.
    call parser_end_stuff (.false.)
    return
  else
    if (global_com%type_out) then
       call out_io (s_info$, r_name, 'Taylor_order has changed.', &
           'Taylor_order in digested file: \i4\ ', &
           'Taylor_order now:              \i4\ ', &
           i_array = [lat%input_taylor_order, bmad_com%taylor_order ])
    endif
    if (lat%input_taylor_order > bmad_com%taylor_order) bp_com%write_digested = .false.
  endif
endif

if (present(digested_read_ok)) digested_read_ok = .false.

! save lattice for possible Taylor map reuse.

old_lat = lat

! here if not OK bmad_status. So we have to do everything from scratch...
! init variables.

call init_lat (lat, 1)
call init_lat (in_lat, 1000)
call init_lat (lat2, 20)
allocate (in_indexx(0:1000), in_name(0:1000))

call allocate_plat (plat, ubound(in_lat%ele, 1))

do i = 0, ubound(in_lat%ele, 1)
  in_lat%ele(i)%ixx = i   ! Pointer to plat%ele() array
enddo

if (global_com%type_out) call out_io (s_info$, r_name, 'Parsing lattice file(s). This might take a few minutes...')
call parser_file_stack('init')
call parser_file_stack('push', lat_file, finished, err)  ! open file on stack
if (err) then
  call parser_end_stuff (.false.)
  return
endif

iseq_tot = 0                            ! number of sequences encountered

call ran_default_state (get_state = bp_com%ran%initial_state) ! Get initial random state.
if (bp_com%ran%initial_state%ix == -1) then
  bp_com%ran%deterministic = 0
else
  bp_com%ran%deterministic = 1
endif

bp_com%input_line_meaningful = .true.
bp_com%ran%ran_function_was_called = .false.
bp_com%ran%deterministic_ran_function_was_called = .false.

in_lat%ele(0)%value(e_tot$) = -1
in_lat%ele(0)%value(p0c$) = -1
call find_indexx2 (in_lat%ele(0)%name, in_name, in_indexx, 0, -1, ix, add_to_list = .true.)

bp_com%beam_ele => in_lat%ele(1)
bp_com%beam_ele%name = 'BEAM'                 ! For mad compatibility.
bp_com%beam_ele%key = def_beam$               ! "definition of beam"
bp_com%beam_ele%value(particle$) = positron$  ! default
call find_indexx2 (in_lat%ele(1)%name, in_name, in_indexx, 0, 0, ix, add_to_list = .true.)

bp_com%param_ele => in_lat%ele(2)
bp_com%param_ele%name = 'PARAMETER'           ! For parameters 
bp_com%param_ele%key = def_parameter$
bp_com%param_ele%value(geometry$) = -1
bp_com%param_ele%value(particle$)     = positron$  ! default
call find_indexx2 (in_lat%ele(2)%name, in_name, in_indexx, 0, 1, ix, add_to_list = .true.)

! The parser actually puts beam_start parameters into in_lat%beam_start so
! the beam_start_ele is actually only needed to act as a place holder.

bp_com%beam_start_ele => in_lat%ele(3)
bp_com%beam_start_ele%name = 'BEAM_START'           ! For beam starting parameters 
bp_com%beam_start_ele%key = def_beam_start$
call find_indexx2 (in_lat%ele(3)%name, in_name, in_indexx, 0, 2, ix, add_to_list = .true.)

n_max => in_lat%n_ele_max
n_max = 3                              ! Number of elements encountered

lat%n_control_max = 0
detected_expand_lattice_cmd = .false.

!-----------------------------------------------------------
! main parsing loop

loop_counter = 0  ! Used for debugging
parsing_loop: do 

  loop_counter = loop_counter + 1

  ! get a line from the input file and parse out the first word.
  call load_parse_line ('normal', 1, end_of_file)  ! load an input line
  call get_next_word (word_1, ix_word, '[:](,)= ', delim, delim_found, .true.)
  if (end_of_file) then
    word_1 = 'END_FILE'
    ix_word = 8
  endif

  ! If input line is something like "quadrupole::*[k1] = ..." then shift delim from ":" to "["

  if (delim == ':' .and. bp_com%parse_line(1:1) == ':') then
    ix = index(bp_com%parse_line, '[')
    if (ix /= 0) then
      word_1 = trim(word_1) // ':' // upcase(bp_com%parse_line(:ix-1))
      bp_com%parse_line = bp_com%parse_line(ix+1:)
      delim = '['
      ix_word = len_trim(word_1)
    endif
  endif

  ! Name check. 
  ! If delim = '[' then have attribute redef and things are complicated so do not check.

  if (delim /= '[') then
    call verify_valid_name(word_1, ix_word)
  endif

  !-------------------------------------------
  ! PARSER_DEBUG

  if (word_1(:ix_word) == 'PARSER_DEBUG') then
    debug_line = bp_com%parse_line
    if (global_com%type_out) call out_io (s_info$, r_name, 'Found in file: "PARSER_DEBUG". Debug is now on')
    cycle parsing_loop
  endif

  !-------------------------------------------
  ! PRINT

  if (word_1(:ix_word) == 'PRINT') then
    call string_trim (bp_com%input_line2, parse_line_save, ix) ! so can strip off initial "print"
    n_ptr => bp_com%num_lat_files
    if (size(bp_com%lat_file_names) < n_ptr + 1) call re_allocate(bp_com%lat_file_names, n_ptr+100)
    n_ptr = n_ptr + 1
    bp_com%lat_file_names(n_ptr) = '!PRINT:' // trim(parse_line_save(ix+2:)) ! To save in digested
    if (global_com%type_out) call out_io (s_dwarn$, r_name, &
                                     'Print Message in Lattice File: ' // parse_line_save(ix+2:))
    ! This prevents bmad_parser from thinking print string is a command.
    call load_parse_line ('init', 1, end_of_file)
    cycle parsing_loop
  endif

  !-------------------------------------------
  ! NO_DIGESTED

  if (word_1(:ix_word) == 'NO_DIGESTED') then
    bp_com%write_digested = .false.
    if (global_com%type_out) call out_io (s_info$, r_name, &
                            'Found in file: "NO_DIGESTED". No digested file will be created')
    cycle parsing_loop
  endif

  !-------------------------------------------
  ! NO_SUPERIMPOSE

  if (word_1(:ix_word) == 'NO_SUPERIMPOSE') then
    bp_com%do_superimpose = .false.
    cycle parsing_loop
  endif

  !-------------------------------------------
  ! DEBUG_MARKER is used to be able to easily set a break within the debugger

  if (word_1(:ix_word) == 'DEBUG_MARKER') then
    word_1 = 'ABC'          ! An executable line to set a break on
    cycle parsing_loop
  endif

  !-------------------------------------------
  ! USE command...

  if (word_1(:ix_word) == 'USE') then
    lat%use_name = ''
    do
      if (delim /= ',') call parser_error ('MISSING COMMA IN "USE" STATEMENT.')
      call get_next_word(word_2, ix_word, ':(=,)', delim, delim_found, .true.)
      if (ix_word == 0) then 
        call parser_error ('CONFUSED "USE" STATEMENT', '')
        cycle parsing_loop
      endif
      call verify_valid_name(word_2, ix_word)
      lat%use_name = trim(lat%use_name) // ',' // word_2
      if (.not. delim_found .and. bp_com%parse_line == '') then
        lat%use_name = lat%use_name(2:)   ! Trim initial comma
        cycle parsing_loop
      endif
    enddo
  endif

  !-------------------------------------------
  ! TITLE command

  if (word_1(:ix_word) == 'TITLE') then
    if (delim_found) then
      if (delim /= " " .and. delim /= ",") call parser_error ('BAD DELIMITOR IN "TITLE" COMMAND')
      call bmad_parser_type_get (this_ele, 'DESCRIP', delim, delim_found)
      lat%title = this_ele%descrip
      deallocate (this_ele%descrip)
    else
      read (bp_com%current_file%f_unit, '(a)') lat%title
      bp_com%current_file%i_line = bp_com%current_file%i_line + 1
    endif
    cycle parsing_loop
  endif

  !-------------------------------------------
  ! CALL command

  if (word_1(:ix_word) == 'CALL') then
    call get_called_file(delim, call_file, xsif_called, err)
    if (err) then
      call parser_end_stuff ()
      return
    endif

    if (xsif_called) then
      call parser_error ('XSIF_PARSER TEMPORARILY DISABLED. PLEASE SEE DCS.')
      if (global_com%exit_on_error) call err_exit
      ! call xsif_parser (call_file, lat, make_mats6, digested_read_ok, use_line) 
      detected_expand_lattice_cmd = .true.
      goto 8000  ! Skip the lattice expansion since xsif_parser does this
    endif

    cycle parsing_loop
  endif

  !-------------------------------------------
  ! BEAM command

  if (word_1(:ix_word) == 'BEAM') then
    if (delim /= ',') call parser_error ('"BEAM" NOT FOLLOWED BY COMMA')
    do 
      if (.not. delim_found) exit
      if (delim /= ',') then
        call parser_error ('EXPECTING: "," BUT GOT: ' // delim, 'FOR "BEAM" COMMAND')
        exit
      endif
      call parser_set_attribute (def$, bp_com%beam_ele, in_lat, delim, delim_found, err)
    enddo
    cycle parsing_loop
  endif

  !-------------------------------------------
  ! EXPAND_LATTICE command

  if (word_1(:ix_word) == 'EXPAND_LATTICE') then
    detected_expand_lattice_cmd = .true.
    exit parsing_loop
  endif

  !-------------------------------------------
  ! RETURN or END_FILE command

  if (word_1(:ix_word) == 'RETURN' .or.  word_1(:ix_word) == 'END_FILE') then
    call parser_file_stack ('pop', ' ', finished, err)
    if (err) then
      call parser_end_stuff ()
      return
    endif
    if (finished) exit parsing_loop ! break loop
    cycle parsing_loop
  endif

  !-------------------------------------------
  ! if an element attribute redef

  if (delim == '[') then

    call get_next_word (word_2, ix_word, ']', delim, delim_found, .true.)
    if (.not. delim_found) then
      call parser_error ('OPENING "[" FOUND WITHOUT MATCHING "]"')
      cycle parsing_loop
    endif

    call get_next_word (this_name, ix_word, ':=', delim, delim_found, .true.)
    if (.not. delim_found .or. ix_word /= 0) then
      call parser_error ('MALFORMED ELEMENT ATTRIBUTE REDEFINITION')
      cycle parsing_loop
    endif

    ! If delim is ':' then this is an error since get_next_word treats
    ! a ':=' construction as a '=' 

    if (delim == ':') then
      call parser_error ('MALFORMED ELEMENT ATTRIBUTE REDEF')
      cycle parsing_loop
    endif

    ! Find associated element and evaluate the attribute value...

    err_if_not_found = (.not. word_1(1:1) == '+') 
    if (word_1(1:1) == '+') word_1 = word_1(2:)

    ixc = index(word_1, '::')
    wild_here = (index(word_1, '*') /= 0 .or. index(word_1, '%') /= 0) ! Wild card character found
    key = key_name_to_key_index(word_1)
    parse_line_save = trim(word_2) // ' = ' // bp_com%parse_line 

    ! If just a name then we can look this up

    if (ixc == 0 .and. key == -1 .and. .not. wild_here) then    
      call find_indexx2 (word_1, in_name, in_indexx, 0, n_max, ix)
      if (ix == -1) then
        call parser_error ('ELEMENT NOT FOUND: ' // word_1)
      else
        ele => in_lat%ele(ix)
        bp_com%parse_line = parse_line_save
        call parser_set_attribute (redef$, ele, in_lat, delim, delim_found, err, plat%ele(ele%ixx))
        if (.not. err .and. delim_found) call parser_error ('BAD DELIMITER: ' // delim)
      endif
      bp_com%parse_line = ''  ! Might be needed in case of error.
      cycle parsing_loop
    endif

    ! Not a simple name so have to loop over all elements and look for a match

    if (any(word_1 == key_name)) then   ! If Old style "quadrupole[k1] = ..." syntax
      name = '*'
      err_if_not_found = .false.

    elseif (ixc == 0) then   ! Simple element name: "q01w[k1] = ..."
      key = 0
      name = word_1

    else                    ! "key::name" syntax
      key = key_name_to_key_index(word_1(1:ixc-1), .true.)
      name = word_1(ixc+2:)
      if (key == -1) then
        bp_com%parse_line = ''
        call parser_error ('BAD ELEMENT CLASS NAME: ' // word_1(1:ixc-1))
        cycle parsing_loop
      endif
    endif

    ! When setting an attribute for all elements then suppress error printing

    ele_found = .false.

    !! print_err = (key == 0 .and. word_1 /= '*')   ! False only when word_1 = "*"

    this_ele%key = key
    if (key == 0) this_ele%key = overlay$
    if (attribute_index (this_ele, word_2)  == 0) then
      call parser_error ('BAD ATTRIBUTE')
      bp_com%parse_line = '' 
      cycle parsing_loop
    endif

    do i = 0, n_max
      ele => in_lat%ele(i)
      if (key /= 0 .and. ele%key /= key) cycle
      ! No wild card matches permitted for these.
      if (ele%key == init_ele$ .or. ele%key == def_beam$ .or. &
          ele%key == def_parameter$ .or. ele%key == def_beam_start$) cycle
      if (.not. match_wild(ele%name, trim(name))) cycle
      ! 
      if (key == 0 .and. wild_here) then
        if (attribute_index(ele, word_2) < 1) cycle
      endif
      bp_com%parse_line = parse_line_save
      ele_found = .true.
      wild_and_key0 = (key == 0 .and. wild_here)
      call parser_set_attribute (redef$, ele, in_lat, delim, delim_found, err, plat%ele(ele%ixx), wild_and_key0 = wild_and_key0)
      if (err .or. delim_found) then
        if (.not. err .and. delim_found) call parser_error ('BAD DELIMITER: ' // delim)
        bp_com%parse_line = '' 
        cycle parsing_loop
      endif
    enddo

    bp_com%parse_line = '' ! Needed if last call to parser_set_attribute did not have a set.

    if (.not. ele_found .and. err_if_not_found) call parser_error ('ELEMENT NOT FOUND OR BAD ATTRIBUTE.')

    cycle parsing_loop
  endif

  !-------------------------------------------
  ! variable def

  if (delim == '=') then

    call parser_add_variable (word_1, in_lat)
    cycle parsing_loop

  endif

  !-------------------------------------------
  ! if a "(" delimitor then we are looking at a replacement line.

  if (delim == '(') then
    call get_sequence_args (word_1, sequence(iseq_tot+1)%dummy_arg, delim, err)
    ix = size(sequence(iseq_tot+1)%dummy_arg)
    allocate (sequence(iseq_tot+1)%corresponding_actual_arg(ix))
    if (err) cycle parsing_loop
    arg_list_found = .true.
    call get_next_word (word_2, ix_word, '(): =,', delim, delim_found, .true.)
    if (word_2 /= ' ') call parser_error &
                ('":" NOT FOUND AFTER REPLACEMENT LINE ARGUMENT LIST. ' // &
                'FOUND: ' // word_2, 'FOR LINE: ' // word_1)
  else
    arg_list_found = .false.
  endif

  ! must have a ":" delimiter now

  if (delim /= ':') then
    call parser_error ('1ST DELIMITER IS NOT ":". IT IS: ' // delim,  &
                                                     'FOR: ' // word_1)
    cycle parsing_loop
  endif

  ! only possibilities left are: element, list, or line
  ! to decide which look at 2nd word

  call get_next_word(word_2, ix_word, ':=,', delim, delim_found, .true.)
  if (ix_word == 0) then
    call parser_error ('NO NAME FOUND AFTER: ' // word_1, ' ')
    call parser_end_stuff 
    return
  endif

  if (word_2 == 'LINE[MULTIPASS]') then
    word_2 = 'LINE'
    ix_word = 4
    multipass = .true.
  else
    multipass = .false.
  endif

  call verify_valid_name(word_2, ix_word)

  ! arg lists are only used with lines

  if (word_2(:ix_word) /= 'LINE' .and. arg_list_found) then
    call parser_error ('ARGUMENTS "XYZ(...):" ARE ONLY USED WITH REPLACEMENT LINES.', &
                                                      'FOR: ' // word_1)
    cycle parsing_loop
  endif

  !-------------------------------------------------------
  ! if line or list

  if (word_2(:ix_word) == 'LINE' .or. word_2(:ix_word) == 'LIST') then
    iseq_tot = iseq_tot + 1
    if (iseq_tot > size(sequence)-1) then
      call out_io (s_fatal$, r_name, 'ERROR IN BMAD_PARSER: NEED TO INCREASE LINE ARRAY SIZE!')
      if (global_com%exit_on_error) call err_exit
    endif

    sequence(iseq_tot)%name = word_1
    sequence(iseq_tot)%multipass = multipass

    if (delim /= '=') call parser_error ('EXPECTING: "=" BUT GOT: ' // delim)
    if (word_2(:ix_word) == 'LINE') then
      if (arg_list_found) then
        sequence(iseq_tot)%type = replacement_line$
      else
        sequence(iseq_tot)%type = line$
        call new_element_init(err)
        ele => in_lat%ele(n_max)
        ele%key = init_ele$
        ele%value(particle$) = real_garbage$
        ele%value(geometry$) = real_garbage$
        ele%value(rel_tracking_charge$) = real_garbage$
        ele%value(e_tot$) = -1
        ele%value(p0c$) = -1
      endif
    else
      sequence(iseq_tot)%type = list$
    endif
    call seq_expand1 (sequence, iseq_tot, in_lat, .true.)

    cycle parsing_loop
  endif

  !-------------------------------------------------------
  ! if not line or list then must be an element

  call new_element_init(err)
  if (err) cycle parsing_loop

  ! Check for valid element key name or if element is part of a element key.
  ! If none of the above then we have an error.

  match_found = .false.  ! found a match?

  call find_indexx2 (word_2, in_name, in_indexx, 0, n_max, i)
  if (i >= 0 .and. i < n_max) then ! i < n_max avoids "abc: abc" construct.
    in_lat%ele(n_max) = in_lat%ele(i)
    in_lat%ele(n_max)%ixx = n_max  ! Restore correct value
    in_lat%ele(n_max)%name = word_1
    match_found = .true.
  endif

  if (.not. match_found) then
    in_lat%ele(n_max)%key = key_name_to_key_index(word_2, .true.)
    if (in_lat%ele(n_max)%key > 0) then
      call set_ele_defaults (in_lat%ele(n_max))
      match_found = .true.
    endif
  endif

  if (.not. match_found) then
    call parser_error ('KEY NAME NOT RECOGNIZED OR AMBIGUOUS: ' // word_2,  &
                  'FOR ELEMENT: ' // in_lat%ele(n_max)%name)
    cycle parsing_loop
  endif

  ! Element definition...
  ! Overlay/group/girder case.

  key = in_lat%ele(n_max)%key
  if (key == overlay$ .or. key == group$ .or. key == girder$) then
    if (delim /= '=') then
      call parser_error ('EXPECTING: "=" BUT GOT: ' // delim,  &
                  'FOR ELEMENT: ' // in_lat%ele(n_max)%name)
      cycle parsing_loop        
    endif

    if (key == overlay$) in_lat%ele(n_max)%lord_status = overlay_lord$
    if (key == group$)   in_lat%ele(n_max)%lord_status = group_lord$
    if (key == girder$)  in_lat%ele(n_max)%lord_status = girder_lord$

    call get_overlay_group_names(in_lat%ele(n_max), in_lat, &
                                                plat%ele(n_max), delim, delim_found)

    if (key /= girder$ .and. .not. delim_found) then
      call parser_error ('NO CONTROL ATTRIBUTE GIVEN AFTER CLOSING "}"',  &
                    'FOR ELEMENT: ' // in_lat%ele(n_max)%name)
      cycle parsing_loop
    endif

  endif

  ! Not overlay/group/girder case.
  ! Loop over all attributes...

  do 
    if (.not. delim_found) exit   ! If no delim then we are finished with this element.
    if (delim /= ',') then
      call parser_error ('EXPECTING: "," BUT GOT: ' // delim,  &
                    'FOR ELEMENT: ' // in_lat%ele(n_max)%name)
      exit
    endif
    call parser_set_attribute (def$, in_lat%ele(n_max), in_lat, delim, delim_found, err, plat%ele(n_max))
    if (err) cycle parsing_loop
  enddo

enddo parsing_loop       ! main parsing loop

!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
! we now have read in everything. 

bp_com%input_line_meaningful = .false.

! sort elements and lists and check for duplicates
! seq_name(:) and in_name(:) arrays speed up the calls to find_indexx since
! the compiler does not have to repack the memory.

allocate (seq_indexx(iseq_tot), seq_name(iseq_tot))
seq_name = sequence(1:iseq_tot)%name
call indexx (seq_name, seq_indexx)

do i = 1, iseq_tot-1
  ix1 = seq_indexx(i)
  ix2 = seq_indexx(i+1)
  if (sequence(ix1)%name == sequence(ix2)%name) call parser_error  &
                    ('DUPLICATE LINE NAME ' // sequence(ix1)%name)
enddo

do i = 1, n_max-1
  ix1 = in_indexx(i)
  ix2 = in_indexx(i+1)
  if (in_lat%ele(ix1)%name == in_lat%ele(ix2)%name) call parser_error &
                  ('DUPLICATE ELEMENT NAME ' // in_lat%ele(ix1)%name)
enddo

!----------------------------------------------------------------------
! Expand all branches...

if (present (use_line)) then
  if (use_line /= '') call str_upcase (lat%use_name, use_line)
endif

if (lat%use_name == blank_name$) then
  call parser_error ('NO "USE" STATEMENT FOUND.', 'I DO NOT KNOW WHAT LINE TO USE!')
  call parser_end_stuff ()
  return
endif

use_line_str = lat%use_name
n_branch_ele = 0
allocate (branch_ele(20))

n_branch_max = 1000
branch_loop: do i_loop = 1, n_branch_max

  ! Expand branches from branch elements before expanding branches from the use command. 

  if (n_branch_ele /= 0) then
    ele => branch_ele(1)%ele
    call parser_add_branch (ele, lat, sequence, in_name, in_indexx, seq_name, seq_indexx, in_lat, plat, created_new_branch)
    this_name = ele%component_name
    is_photon_branch = (ele%key == photon_branch$)
    n_branch_ele = n_branch_ele - 1
    branch_ele(1:n_branch_ele) = branch_ele(2:n_branch_ele+1)
    if (.not. created_new_branch) cycle 

  else
    if (use_line_str == '') exit
    ix = index(use_line_str, ',')
    if (ix == 0) then
      this_name = use_line_str
      use_line_str = ''
    else
      this_name = use_line_str(1:ix-1)
      use_line_str = use_line_str(ix+1:)
    endif

    call parser_expand_line (lat, this_name, sequence, in_name, in_indexx, seq_name, seq_indexx, in_lat, n_ele_use)
    is_photon_branch = .false.
  endif

  n_branch = ubound(lat%branch, 1)
  branch => lat%branch(n_branch)

  call find_indexx2 (this_name, in_name, in_indexx, 0, n_max, ix)
  ele => in_lat%ele(ix)    
  ele0 => branch%ele(0)

  ele0%value(e_tot$) = -1
  ele0%value(p0c$)   = -1 


  ! Add energy, species, etc info for all branches except branch(0) which is handled "old style".

  if (n_branch == 0) then
    lat%ele(0)     = in_lat%ele(0)    ! Beginning element
    lat%version = bmad_inc_version$
    lat%input_file_name         = full_lat_file_name             ! save input file  

    lat%beam_start = in_lat%beam_start
    lat%a          = in_lat%a
    lat%b          = in_lat%b
    lat%z          = in_lat%z
    lat%absolute_time_tracking      = in_lat%absolute_time_tracking
    lat%rf_auto_scale_phase         = in_lat%rf_auto_scale_phase
    lat%rf_auto_scale_amp           = in_lat%rf_auto_scale_amp
    lat%use_ptc_layout              = in_lat%use_ptc_layout
    if (allocated(lat%attribute_alias)) deallocate(lat%attribute_alias)
    call move_alloc (in_lat%attribute_alias, lat%attribute_alias)

    call mat_make_unit (lat%ele(0)%mat6)
    call clear_lat_1turn_mats (lat)

    if (bp_com%beam_ele%value(n_part$) /= 0 .and. bp_com%param_ele%value(n_part$) /= 0) &
              call parser_error ('BOTH "PARAMETER[N_PART]" AND "BEAM, N_PART" SET.')
    lat%param%n_part = max(bp_com%beam_ele%value(n_part$), bp_com%param_ele%value(n_part$))

    ix1 = nint(bp_com%param_ele%value(particle$))
    ix2 = nint(bp_com%beam_ele%value(particle$))
    if (ix1 /= positron$ .and. ix2 /= positron$) &
            call parser_error ('BOTH "PARAMETER[PARTICLE]" AND "BEAM, PARTICLE" SET.')
    lat%param%particle = ix1
    if (ix2 /=  positron$) lat%param%particle = ix2

    ! The lattice name from a "parameter[lattice] = ..." line is 
    ! stored the bp_com%param_ele%descrip string

    if (associated(bp_com%param_ele%descrip)) then
      lat%lattice = bp_com%param_ele%descrip
      deallocate (bp_com%param_ele%descrip)
    endif

    ! Set geometry.

    ix = nint(bp_com%param_ele%value(geometry$))
    if (ix > 0) then  ! geometry has been set.
      lat%param%geometry = ix
    else              ! else use default
      lat%param%geometry = closed$      ! default 
      if (any(in_lat%ele(:)%key == lcavity$)) then    !   except...
        if (global_com%type_out) call out_io (s_warn$, r_name, 'NOTE: THIS LATTICE HAS A LCAVITY.', &
                                      'SETTING THE GEOMETRY TO LINEAR_LATTICE.')
        lat%param%geometry = open$
      endif
    endif

  endif

  !----

  if (ele%value(particle$) == real_garbage$) then
    if (is_photon_branch) then
      branch%param%particle = photon$
    else
      branch%param%particle = lat%param%particle
    endif
  else
    branch%param%particle = ele%value(particle$)
  endif

  if (ele%value(geometry$) /= real_garbage$) branch%param%geometry = nint(ele%value(geometry$))
  if (ele%value(rel_tracking_charge$) /= real_garbage$) &
                                   branch%param%rel_tracking_charge = nint(ele%value(rel_tracking_charge$))

  if (ele%value(p0c$)>= 0)        ele0%value(p0c$)   = ele%value(p0c$)
  if (ele%value(e_tot$)>= 0)      ele0%value(e_tot$) = ele%value(e_tot$)
  if (ele%a%beta /= 0)            ele0%a             = ele%a
  if (ele%b%beta /= 0)            ele0%b             = ele%b
  if (ele%value(floor_set$) /= 0) ele0%floor         = ele%floor 

  if (bp_com%error_flag) then
    call parser_end_stuff ()
    return
  endif

  ! Go through the IN_LAT elements and put in the superpositions.
  ! If the superposition is a branch element, need to add the branch line.

  call s_calc (lat)              ! calc longitudinal distances
  call control_bookkeeper (lat)

  do i = 1, n_max
    if (in_lat%ele(i)%lord_status /= super_lord$) cycle
    call add_all_superimpose (branch, in_lat%ele(i), plat%ele(i), in_lat)
    call s_calc (lat)  ! calc longitudinal distances of new branch elements
  enddo

  ! Add branch lines to the list of branches to construct.

  j = 0
  do i = 1, branch%n_ele_max
    if (branch%ele(i)%key /= photon_branch$ .and. branch%ele(i)%key /= branch$) cycle
    j = j + 1
    n_branch_ele = n_branch_ele + 1
    call re_allocate_eles (branch_ele, n_branch_ele + 10, .true., .false.)
    branch_ele(j+1:n_branch_ele) = branch_ele(j:n_branch_ele-1)
    branch_ele(j)%ele => branch%ele(i)
  enddo

  if (i_loop == n_branch_max) then
    call parser_error ('1000 BRANCHES GENERATED. LOOKS LIKE AN ENDLESS LOOP')
    call parser_end_stuff ()
    return
  endif 

enddo branch_loop

!--------------------------------------------
! Reference energy bookkeeping. 

do i = 0, ubound(lat%branch, 1)
  branch => lat%branch(i)

  ! Do not need to have set the energy for branch lines where the particle is the same
  if (branch%ix_from_branch > -1) then
    branch0 => lat%branch(branch%ix_from_branch)
    if (branch0%param%particle == branch%param%particle) cycle
  endif

  ele => branch%ele(0)

  if (ele%value(p0c$) >= 0) then
    call convert_pc_to (ele%value(p0c$), branch%param%particle, e_tot = ele%value(e_tot$))
  elseif (ele%value(e_tot$) >= mass_of(branch%param%particle)) then
    call convert_total_energy_to (ele%value(e_tot$), branch%param%particle, pc = ele%value(p0c$))
  else
    if (global_com%type_out) then
      if (ele%value(e_tot$) < 0 .and. ele%value(p0c$) < 0) then
        call out_io (s_warn$, r_name, 'REFERENCE ENERGY IS NOT SET IN BRANCH: (\i0\) ' // branch%name, &
                                       'WILL USE 1000 * MC^2!', i_array = [i])
      else
        call out_io (s_error$, r_name, 'REFERENCE ENERGY IS SET BELOW MC^2 IN BRANCH (\i0\) ' // branch%name,  ' WILL USE 1000 * MC^2!')
      endif
    endif
    ele%value(e_tot$) = 1000 * mass_of(branch%param%particle)
    call convert_total_energy_to (ele%value(e_tot$), branch%param%particle, pc = ele%value(p0c$))
    bp_com%write_digested = .false.
  endif

  ele%value(e_tot_start$) = ele%value(e_tot$)
  ele%value(p0c_start$) = ele%value(p0c$)

enddo 

! Work on multipass...
! Multipass elements are paired by ele%iyy tag and ele%name must both match.

do ib = 0, ubound(lat%branch, 1)
  do ie = 1, lat%branch(ib)%n_ele_max
    ele => lat%branch(ib)%ele(ie)
    if (ele%iyy == 0) cycle
    if (ele%slave_status == super_slave$) cycle
    if (ele%key == null_ele$) cycle
    n_multi = 0  ! number of elements to slave together
    iyy = ele%iyy
    do ib2 = ib, ubound(lat%branch, 1)
      do ie2 = 1, lat%branch(ib2)%n_ele_max
        if (ib == ib2 .and. ie2 < ie) cycle
        ele2 => lat%branch(ib2)%ele(ie2)
        if (ele2%iyy /= iyy) cycle
        if (ele2%name /= ele%name) cycle
        n_multi = n_multi + 1
        m_slaves(n_multi) = ele_to_lat_loc (ele2)
        ele2%iyy = 0  ! mark as taken care of
      enddo
    enddo
    call add_this_multipass (lat, m_slaves(1:n_multi))
  enddo
enddo

!-------------------------------------
! If a girder elements refer to a line then must expand that line.

do i = 1, n_max
  lord => in_lat%ele(i)
  if (lord%lord_status /= girder_lord$) cycle
  pele => plat%ele(i)
  j = 0
  do 
    j = j + 1
    if (j > lord%n_slave) exit
    call find_indexx(pele%name(j), seq_name, seq_indexx, size(seq_name), k, k2)
    if (k == 0) cycle
    call init_lat (lat2)
    call parser_expand_line (lat2, pele%name(j), sequence, in_name, in_indexx, &
                                      seq_name, seq_indexx, in_lat, n_ele_use, .false.)
    ! Put elements from the line expansion into the slave list.
    ! Remember to ignore drifts.
    lord%n_slave = lord%n_slave - 1   ! Remove beam line name
    pele%name(1:lord%n_slave) = [pele%name(1:j-1), pele%name(j+1:lord%n_slave+1)]
    call re_allocate (pele%name, lord%n_slave+n_ele_use)
    do k = 1, n_ele_use
      call find_indexx2 (lat2%ele(k)%name, in_name, in_indexx, 0, n_max, ix, ix2)      
      if (ix /= 0) then
        if (in_lat%ele(ix)%key == drift$) cycle
      endif
      lord%n_slave = lord%n_slave + 1
      pele%name(lord%n_slave) = lat2%ele(k)%name
    enddo
  enddo
enddo

! PTC stuff.
! Use arbitrary energy above the rest mass energy since when tracking individual elements the
! true reference energy is used.

lat%input_taylor_order = nint(bp_com%param_ele%value(taylor_order$))
if (lat%input_taylor_order /= 0) call set_taylor_order (lat%input_taylor_order, .false.)

call set_ptc (1000*mass_of(lat%param%particle), lat%param%particle)

! Error check that if a superposition attribute was set that "superposition" was set.

do i = 1, n_max
  if (in_lat%ele(i)%lord_status == super_lord$) cycle
  pele => plat%ele(i)
  if (pele%ref_name /= blank_name$ .or. pele%s /= 0 .or. &
      pele%ele_pt /= not_set$ .or. pele%ref_pt /= not_set$) then
    call parser_error ('SUPERPOSITION ATTRIBUTE SET BUT "SUPERPOSITION" NOT SPECIFIED FOR: ' // in_lat%ele(i)%name)
  endif
enddo


! Now put in the overlay_lord, girder, and group elements

call parser_add_lord (in_lat, n_max, plat, lat)

! Consistancy check

call lat_sanity_check (lat, err)
if (err) then
  bp_com%error_flag = .true.
  call parser_end_stuff
  return
endif

! Reuse the old taylor series if they exist
! and the old taylor series has the same attributes.

if (logic_option (.true., make_mats6)) then
  call lattice_bookkeeper (lat, err)
  if (err) then
    bp_com%error_flag = .true.
    call parser_end_stuff
    return
  endif
endif

lat%input_taylor_order = bmad_com%taylor_order

! Do we need to expand the lattice and call bmad_parser2?

8000 continue

if (detected_expand_lattice_cmd) then
  exit_on_error = global_com%exit_on_error
  global_com%exit_on_error = .false.
  bp_com%bmad_parser_calling = .true.
  bp_com%old_lat => in_lat
  call bmad_parser2 ('FROM: BMAD_PARSER', lat, make_mats6 = .false.)
  bp_com%bmad_parser_calling = .false.
  global_com%exit_on_error = exit_on_error
endif

! Remove all null_ele elements and init custom stuff.

do n = 0, ubound(lat%branch, 1)
  branch => lat%branch(n)
  do i = 1, branch%n_ele_max
    ele => branch%ele(i)
    if (ele%key == null_ele$) ele%key = -1 ! mark for deletion
    if (ele%key == custom$ .or. ele%tracking_method == custom$ .or. &
        ele%mat6_calc_method == custom$ .or. ele%field_calc == custom$ .or. &
        ele%aperture_type == custom$) then
      call init_custom (ele, err)
      if (err) bp_com%error_flag = .true.
    endif
  enddo
enddo
call remove_eles_from_lat (lat, .false.)  

! Make the transfer matrices.
! Note: The bmad_parser err_flag argument does *not* include errors in 
! lat_make_mat6 since if there is a match element, there is an error raised 
! here since the Twiss parameters have not been set. But this is expected. 

call reuse_taylor_elements (old_lat, lat)
if (logic_option (.true., make_mats6)) call lat_make_mat6(lat, -1) 

! Wall3d init.

do i = 0, ubound(lat%branch, 1)
  branch => lat%branch(i)

  n_wall = 0
  do j = 0, branch%n_ele_track
    ele => branch%ele(j)
    if (.not. associated(ele%wall3d)) cycle
    call wall3d_initializer (ele%wall3d, err)
    if (err) then
      call parser_end_stuff (.false.)
      return
    endif
    if (ele%key == capillary$) cycle
    n_wall = n_wall + size(ele%wall3d%section)
  enddo

  ! Aggragate vacuum chamber wall info for a branch to branch%wall3d structure

  ! NOTE: This code needs to be modified to take care of continuous aperture walls and 
  ! wall priorities. OR: Is the branch%wall3d component even needed?

  if (n_wall == 0) cycle
  cycle   ! NOTE: AGGRAGATING CODE DISABLED FOR NOW UNTIL SOMEONE NEEDS IT!

  allocate (branch%wall3d)
  allocate (branch%wall3d%section(n_wall))
  n_wall = 0
  do j = 0, branch%n_ele_track
    ele => branch%ele(j)
    if (ele%key == capillary$) cycle
    if (.not. associated(ele%wall3d)) cycle
    n = size(ele%wall3d%section)
    branch%wall3d%section(n_wall+1:n_wall+n) = ele%wall3d%section
    branch%wall3d%section(n_wall+1:n_wall+n)%s = branch%wall3d%section(n_wall+1:n_wall+n)%s + &
                                                                              ele%s - ele%value(l$)
    n_wall = n_wall + n
  enddo

enddo

! Correct beam_start info

call init_coord (lat%beam_start, lat%beam_start, lat%ele(0), .true., shift_vec6 = .false.)

!-------------------------------------------------------------------------
! write out if debug is on

if (debug_line /= '') call parser_debug_print_info (lat, debug_line)

! write to digested file

if (.not. bp_com%error_flag) then            
  bp_com%write_digested = bp_com%write_digested .and. digested_version <= bmad_inc_version$
  if (bp_com%write_digested) then
    call write_digested_bmad_file (digested_file, lat, bp_com%num_lat_files, &
                                                            bp_com%lat_file_names, bp_com%ran, err)
    if (.not. err .and. global_com%type_out) call out_io (s_info$, r_name, 'Created new digested file')
  endif
endif

call parser_end_stuff ()

if (bp_com%ran%ran_function_was_called) then
  if (global_com%type_out) call out_io(s_warn$, r_name, &
                'NOTE: THE RANDOM NUMBER FUNCTION WAS USED IN THE LATTICE FILE SO THIS', &
                '      LATTICE WILL DIFFER FROM OTHER LATTICES GENERATED FROM THE SAME FILE.')
endif

!---------------------------------------------------------------------
contains

subroutine parser_end_stuff (do_dealloc)

logical, optional :: do_dealloc
integer i, j

! Restore auto_bookkeeper flag

bmad_com%auto_bookkeeper = auto_bookkeeper_saved

! deallocate pointers

if (logic_option (.true., do_dealloc)) then

  do i = 1, size(sequence(:))
    if (associated (sequence(i)%dummy_arg)) &
              deallocate(sequence(i)%dummy_arg, sequence(i)%corresponding_actual_arg)
    if (associated (sequence(i)%ele)) then
      do j = 1, size(sequence(i)%ele)
        if (associated (sequence(i)%ele(j)%actual_arg)) &
                              deallocate(sequence(i)%ele(j)%actual_arg)
      enddo
      deallocate(sequence(i)%ele)
    endif
  enddo

  if (allocated (seq_indexx))            deallocate (seq_indexx, seq_name)
  if (allocated (in_indexx))             deallocate (in_indexx, in_name)
  if (allocated (bp_com%lat_file_names)) deallocate (bp_com%lat_file_names)

endif

if (bp_com%error_flag) then
  if (global_com%exit_on_error) then
    call out_io (s_fatal$, r_name, 'BMAD_PARSER FINISHED. EXITING ON ERRORS')
    stop
  endif
endif

if (present(err_flag)) err_flag = bp_com%error_flag

! Check wiggler for integer number of periods

do i = 1, lat%n_ele_max
  ele => lat%ele(i)
  if (ele%key /= wiggler$) cycle
  if (ele%sub_key /= periodic_type$) cycle
  if (ele%slave_status == super_slave$) cycle
  if (abs(modulo2(ele%value(n_pole$) / 2, 0.5_rp)) > 0.01) then
    call out_io (s_warn$, r_name, [&
          '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!', &
          '!!!!! WARNING! WIGGLER: ' // ele%name, &
          '!!!!! DOES NOT HAVE AN EVEN NUMBER OF POLES!                    ', &
          '!!!!! THIS WILL BE PROBLEMATIC IF YOU ARE USING TAYLOR MAPS!    ', &
          '!!!!! SEE THE BMAD MANUAL FOR MORE DETAILS!                     ', &
          '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!' ])
  endif
enddo

call deallocate_lat_pointers(old_lat)
call deallocate_lat_pointers(in_lat)
call deallocate_lat_pointers(lat2)

end subroutine parser_end_stuff 

!---------------------------------------------------------------------
! contains

subroutine new_element_init (err)

logical err

!

if (word_1 == 'BEGINNING' .or. word_1 == 'BEAM' .or. word_1 == 'BEAM_START' .or. &
    word_1 == 'END') then
  call parser_error ('ELEMENT NAME CORRESPONDS TO A RESERVED WORD: ' // word_1)
  err = .true.
  return
endif

err = .false.

n_max = n_max + 1
if (n_max > ubound(in_lat%ele, 1)) then
  call allocate_lat_ele_array (in_lat)
  call re_allocate2 (in_name, 0, ubound(in_lat%ele, 1))
  call re_allocate2 (in_indexx, 0, ubound(in_lat%ele, 1))
  bp_com%beam_ele => in_lat%ele(1)
  bp_com%param_ele => in_lat%ele(2)
  bp_com%beam_start_ele => in_lat%ele(3)
  call allocate_plat (plat, ubound(in_lat%ele, 1))
endif

call init_ele (in_lat%ele(n_max), branch = in_lat%branch(0))
in_lat%ele(n_max)%name = word_1
call find_indexx2 (in_lat%ele(n_max)%name, in_name, in_indexx, 0, n_max-1, ix, add_to_list = .true.)
in_lat%ele(n_max)%ixx = n_max  ! Pointer to plat%ele() array

plat%ele(n_max)%lat_file = bp_com%current_file%full_name
plat%ele(n_max)%ix_line_in_file = bp_com%current_file%i_line

end subroutine new_element_init

end subroutine bmad_parser

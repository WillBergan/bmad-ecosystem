!+
! Subroutine tao_parse_command_args (error, cmd_line)
!
! Subroutine to parse the command line arguments.
!
! Input:
!   cmd_words(:) -- Character(*), optional: If present then this is used
!                    in place of the command line.
! Output:
!   error -- Logical: Set True if there is an error. False otherwise.
!-

subroutine tao_parse_command_args (error, cmd_line)

use tao_interface, dummy => tao_parse_command_args
use tao_command_mod, only: tao_cmd_split

implicit none

character(*), optional :: cmd_line
character(200) :: cmd_words(12)
character(80) arg0, arg1, base, switch
character(24) :: r_name = 'tao_parse_command_args'

integer n_arg, i_arg, ix
logical error, negate

! Get command line input

error = .false.

call tao_hook_parse_command_args()
if (.not. s%com%parse_cmd_args) return

if (present(cmd_line)) then
  call tao_cmd_split(cmd_line, 12, cmd_words, .false., error)
  if (error) return
  n_arg = size(cmd_words)
  if (cmd_words(1) == '') return
else
  n_arg = cesr_iargc()
  if (n_arg == 0) return
endif

! loop over all arguments

i_arg = 0

do 

  if (i_arg == n_arg) exit
  call get_next_arg (arg0)
  if (arg0(1:2) == '--') then
    arg1 = arg0(2:)
    negate = .true.
  else
    arg1 = arg0
    negate = .false.
  endif

  call match_word (arg1, [character(41):: '-?', '-init_file', '-noinit', '-beam_all_file', '-beam0', &
        '-noplot', '-lattice_file', '-log_startup', '-beam_file', '-var_file', '-data_file', '-building_wall_file', &
        '-startup_file', 'help', '-help', '?', '-geometry', '-rf_on', '-debug', '-disable_smooth_line_calc', &
        '-color_prompt', '-no_stopping', '-hook_init_file', '-beam_position0', '-silent_run', &
        '-beam_init_file_name', '-slice_lattice', '-prompt_color', '-beam_init_position_file', &
        '-plot_file', '-external_plotting'], ix, .true., matched_name=switch)

  if (negate) switch = '-' // switch

  !

  select case (switch)

  case ('-beam_file')
    call get_next_arg (s%com%beam_file_arg)

  case ('-beam_all_file')
    call get_next_arg (s%com%beam_all_file_arg)

  case ('-beam_position0', '-beam0', '-beam_init_file_name')
    call get_next_arg (s%com%beam_init_position_file_arg)
    call out_io (s_warn$, r_name, 'Note: Switch: ' // quote(switch) // &
                                ' has been replaced with "-beam_init_position_file"')

  case ('-beam_init_position_file')
    call get_next_arg (s%com%beam_init_position_file_arg)

  case ('-building_wall_file')
    call get_next_arg (s%com%building_wall_file_arg)

  case ('-data_file')
    call get_next_arg (s%com%data_file_arg)

  case ('-disable_smooth_line_calc')
    s%com%disable_smooth_line_calc_arg = '<present>'

  case ('-debug')
    s%com%debug_arg = '<present>'
    s%global%debug_on = .true.
    s%global%stop_on_error = .false.

  case ('-external_plotting')
    s%global%external_plotting = .true.

  case ('-geometry')
    call get_next_arg (s%com%geometry_arg, .true.)

  case ('help', '-help', '?', '-?')
    call tao_print_command_line_info
    stop

  case ('-hook_init_file')
    call get_next_arg (s%com%hook_init_file_arg)

  case ('-init_file')
    call get_next_arg (s%com%init_file_arg)
    ix = SplitFileName(s%com%init_file_arg, s%com%init_file_arg_path, base)

  case ('-lattice_file')
    call get_next_arg (s%com%lattice_file_arg)
    s%com%noinit_arg = ''

  case ('-log_startup')
    s%com%log_startup_arg = '<present>'

  case ('-no_stopping')
    s%com%no_stopping_arg = '<present>'

  case ('-noinit')
    s%com%noinit_arg = '<present>'
    s%com%init_file_arg = ''

  case ('-noplot')
    s%com%noplot_arg = '<present>'

  case ('-plot_file')
    call get_next_arg (s%com%plot_file_arg)

  case ('-prompt_color', '-color_prompt')
    s%com%prompt_color_arg = ''

  case ('-rf_on')
    s%com%rf_on_arg = '<present>'

  case ('-silent_run')
    s%com%silent_run_arg = '<present>'

  case ('-slice_lattice')
    call get_next_arg (s%com%slice_lattice_arg, .true.)

  case ('-startup_file')
    call get_next_arg (s%com%startup_file_arg)

  case ('-var_file')
    call get_next_arg (s%com%var_file_arg)

  case default
    call out_io (s_error$, r_name, 'BAD COMMAND LINE ARGUMENT: ' // arg0)
    call tao_print_command_line_info
    error = .true.
    if (s%global%stop_on_error) stop
    return

  ! Negate cases

  case ('--beam_file');                           s%com%beam_file_arg = ''
  case ('--beam_all_file');                       s%com%beam_all_file_arg = ''
  case ('--beam_position0', '--beam0', '--beam_init_file_name'); 
                                                  s%com%beam_init_position_file_arg = ''
  case ('--beam_init_position_file');             s%com%beam_init_position_file_arg = ''
  case ('--building_wall_file');                  s%com%building_wall_file_arg = ''
  case ('--data_file');                           s%com%data_file_arg = ''
  case ('--disable_smooth_line_calc');            s%com%disable_smooth_line_calc_arg = ''
  case ('--debug');        s%com%debug_arg = '';  s%global%debug_on = .false.;  s%global%stop_on_error = .true.
  case ('--external_plotting');                   s%global%external_plotting = .false.
  case ('--geometry');                            s%com%geometry_arg = ''
  case ('--hook_init_file');                      s%com%hook_init_file_arg = ''
  case ('--init_file');                           s%com%init_file_arg = ''; s%com%init_file_arg_path = ''
  case ('--lattice_file');                        s%com%lattice_file_arg = ''
  case ('--log_startup');                         s%com%log_startup_arg = ''
  case ('--no_stopping');                         s%com%no_stopping_arg = ''
  case ('--noinit');                              s%com%noinit_arg = ''
  case ('--noplot');                              s%com%noplot_arg = ''
  case ('--plot_file');                           s%com%plot_file_arg = ''
  case ('--prompt_color', '--color_prompt');      s%com%prompt_color_arg = ''
  case ('--rf_on');                               s%com%rf_on_arg = ''
  case ('--silent_run');                          s%com%silent_run_arg = ''
  case ('--slice_lattice');                       s%com%slice_lattice_arg = ''
  case ('--startup_file');                        s%com%startup_file_arg = ''
  case ('--var_file');                            s%com%var_file_arg = ''
  end select

enddo

!-----------------------------
contains

subroutine get_next_arg(arg, may_have_blanks)

character(*) arg
character(40) sub
logical, optional :: may_have_blanks

!

if (i_arg == n_arg) then
  call out_io (s_error$, r_name, 'MISSING COMMAND LINE ARGUMENT FOR: ' // arg0)
  error = .true.
  return
endif

i_arg = i_arg + 1

if (present(cmd_line)) then
  arg = cmd_words(i_arg)
  if (cmd_words(i_arg+1) == '') n_arg = i_arg
else
  call cesr_getarg(i_arg, arg)
endif

!

if (logic_option(.false., may_have_blanks)) then
  do
    if (i_arg == n_arg) return

    if (present(cmd_line)) then
      sub = cmd_words(i_arg+1)
    else
      call cesr_getarg(i_arg+1, sub)
    endif

    if (sub(1:1) == '-') return
    arg = trim(arg) // sub
    i_arg = i_arg + 1

    if (present(cmd_line)) then
      if (cmd_words(i_arg+1) == '') n_arg = i_arg
    endif
  enddo
endif

end subroutine get_next_arg

end subroutine tao_parse_command_args


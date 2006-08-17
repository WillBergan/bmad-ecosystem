!+
! Subroutine tao_plot_data_setup ()
!
! Subroutine to set the data for plotting.
! Essentially transfer info from the s%u(:)%data arrays
! to the s%plot_page%region(:)%plot%graph(:)%curve(:) arrays.
!
! Input/Output:
!-

subroutine tao_plot_data_setup ()

use tao_mod
use tao_x_scale_mod
use tao_scale_mod

implicit none

type (tao_plot_struct), pointer :: plot
type (tao_graph_struct), pointer :: graph
type (tao_curve_struct), pointer :: curve
type (ele_struct), pointer :: ele

integer i, ii, k, m, i_uni, ie, jj, ic
integer ix, ir, jg

real(rp) ax_min, ax_max

character(20) :: r_name = 'tao_plot_data_setup'

! Find which elements are to be drawn for a lattice layout.

if (any(s%plot_page%ele_shape(:)%key /= 0)) then
  do i_uni = 1, size(s%u)
    s%u(i_uni)%model%lat%ele_(:)%ix_pointer = 0
    s%u(i_uni)%base%lat%ele_(:)%ix_pointer = 0
    do ie = 1, s%u(i_uni)%model%lat%n_ele_max
      ele => s%u(i_uni)%model%lat%ele_(ie)
      if (ele%control_type == group_lord$) cycle
      if (ele%control_type == overlay_lord$) cycle
      if (ele%control_type == super_slave$) cycle
      if (ele%control_type == multipass_lord$) cycle
      if (ie > s%u(i_uni)%model%lat%n_ele_use .and. &
                                ele%control_type == free$) cycle
      do k = 1, size(s%plot_page%ele_shape(:))
        if (s%plot_page%ele_shape(k)%key == 0) cycle
        if (ele%key == s%plot_page%ele_shape(k)%key .and. &
                 match_wild(ele%name, s%plot_page%ele_shape(k)%ele_name)) then
          ele%ix_pointer = k
          s%u(i_uni)%base%lat%ele_(ie)%ix_pointer = ie
          s%u(i_uni)%base%lat%ele_(ie-1)%ix_pointer = ie-1
          exit
        endif
      enddo
    enddo
  enddo
endif

! setup the plots

plot_loop: do ir = 1, size(s%plot_page%region)

  plot => s%plot_page%region(ir)%plot

  ! Don't worry about invisable graphs
  if (.not. s%plot_page%region(ir)%visible) cycle  

  select case (plot%x_axis_type)
  case ('index', 's', 'ele_index', 'phase_space', 'none')
  case default
    call out_io (s_abort$, r_name, 'BAD X_AXIS_TYPE: ' // plot%x_axis_type)
    plot%graph%valid = .false.
    cycle
  endselect

! loop over all graphs and curves

  do jg = 1, size(plot%graph)
    graph => plot%graph(jg)
    call tao_graph_data_setup (plot, graph)
    if (graph%y%min == graph%y%max) call tao_scale_graph (graph, 0.0_rp, 0.0_rp)
    graph%limited = .false.
    if (allocated(graph%curve)) then
      ax_min = graph%y%min + 1e-6 * (graph%y%min - graph%y%max)
      ax_max = graph%y%max + 1e-6 * (graph%y%max - graph%y%min)
      do ic = 1, size(graph%curve)
        curve => graph%curve(ic)
        if (allocated(curve%y_symb)) then
          if (any(curve%y_symb < ax_min .or. &
                    curve%y_symb > ax_max)) graph%limited = .true.
        endif
        if (allocated(curve%y_line)) then
          if (any(curve%y_line < ax_min .or. &
                    curve%y_line > ax_max)) graph%limited = .true.
        endif
      enddo
    endif
  enddo

  if (plot%x%min == plot%x%max) call tao_x_scale_plot (plot, 0.0_rp, 0.0_rp)

enddo plot_loop

end subroutine

!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!----------------------------------------------------------------------------

subroutine tao_graph_data_setup (plot, graph)

use tao_mod

implicit none

type (tao_plot_struct) plot
type (tao_graph_struct), target :: graph
type (tao_curve_struct), pointer :: curve

integer i
logical found

!

graph%valid = .true.   ! assume everything OK
graph%legend = ' '

call tao_hook_graph_data_setup (plot, graph, found)
if (found) return

select case (graph%type)
case ('phase_space')
  call tao_phase_space_plot_data_setup (plot, graph)
case ('data')
  call tao_data_plot_data_setup(plot, graph)
end select

! Renormalize

if (allocated (graph%curve)) then
  do i = 1, size(graph%curve)
    curve => graph%curve(i)
    if (allocated(curve%x_symb)) then
        curve%x_symb = curve%x_symb * curve%x_axis_scale_factor
        curve%y_symb = curve%y_symb * curve%y_axis_scale_factor
    endif
    if (allocated(curve%x_line)) then
      curve%x_line = curve%x_line * curve%x_axis_scale_factor
      curve%y_line = curve%y_line * curve%y_axis_scale_factor
    endif
  enddo
endif

end subroutine

!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!----------------------------------------------------------------------------

subroutine tao_phase_space_plot_data_setup (plot, graph)

use tao_mod

implicit none

type (tao_plot_struct) plot
type (tao_graph_struct), target :: graph
type (tao_curve_struct), pointer :: curve
type (tao_universe_struct), pointer :: u
type (ele_struct), pointer :: ele
type (tao_d2_data_struct), pointer :: d2_ptr
type (tao_d1_data_struct), pointer :: d1_x, d1_y

real(rp) v_mat(4,4), v_inv_mat(4,4), g_mat(4,4), g_inv_mat(4,4)
real(rp) mat4(4,4), sigma_mat(4,4), theta, theta_xy, rx, ry, phi

integer k, n, m, ib, ix1_ax, ix2_ax, ix, i_uni, i

logical err

character(40) name, phase1_str, phase2_str
character(40) :: r_name = 'tao_phase_space_plot_data_setup'

! Set up the graph suffix

curve => graph%curve(1)

i_uni = curve%ix_universe
if (i_uni == 0) i_uni = s%global%u_view
u => s%u(i_uni)
ele => s%u(i_uni)%model%lat%ele_(curve%ix_ele_ref)

name = curve%ele_ref_name
if (name == ' ') name = ele%name

write (graph%title_suffix, '(a, i0, 3a)') '[', curve%ix_ele_ref, ': ', trim(name), ']'

! loop over all curves

graph%valid = .false.

do k = 1, size(graph%curve)

  curve => graph%curve(k)

  ! find phase space axes to plot

  ix = index(curve%data_type, '-')
  if (ix == 0) then
    call out_io (s_abort$, r_name, 'INVALID PHASE_SPACE CURVE DATA_TYPE: ' // &
                                                                  curve%data_type)
    call err_exit
  endif
  err = .false.
  phase1_str = curve%data_type(:ix-1)
  phase2_str = curve%data_type(ix+1:)
  call tao_phase_space_axis (phase1_str, ix1_ax, err); if (err) return
  call tao_phase_space_axis (phase2_str, ix2_ax, err); if (err) return

  ! fill the curve data arrays

  if (allocated (curve%ix_symb)) deallocate (curve%ix_symb, curve%x_symb, curve%y_symb)
  if (allocated (curve%x_line))  deallocate (curve%x_line, curve%y_line)

  if (curve%data_source == 'beam_tracking') then

    if (.not. allocated(curve%beam%bunch)) then
      call out_io (s_abort$, r_name, 'NO ALLOCATED BEAM WITH PHASE_SPACE PLOTTING.')
      if (.not. u%is_on) call out_io (s_blank$, r_name, '   REASON: UNIVERSE IS TURNED OFF!')
      return
    endif

    n = 0
    do ib = 1,  size(curve%beam%bunch)
      n = size(curve%beam%bunch(ib)%particle)
    enddo

    call re_allocate (curve%ix_symb, n)
    call re_allocate (curve%x_symb, n)
    call re_allocate (curve%y_symb, n)

    n = 0
    do ib = 1, size(curve%beam%bunch)
      m = size(curve%beam%bunch(ib)%particle)
      curve%x_symb(n+1:n+m) = curve%beam%bunch(ib)%particle(:)%r%vec(ix1_ax)
      curve%y_symb(n+1:n+m) = curve%beam%bunch(ib)%particle(:)%r%vec(ix2_ax)
      n = n + m
    enddo

  !----------------------------

  elseif (curve%data_source == 'multi_turn_orbit') then
    
    call tao_find_data (err, curve%data_source, d2_ptr, ix_uni = i_uni)
    if (err) then
      call out_io (s_error$, r_name, &
                'CANNOT FIND DATA ARRAY TO PLOT CURVE: ' // curve%data_type)
      graph%valid = .false.
      return
    endif

    nullify (d1_x, d1_y)
    do i = 1, size(d2_ptr%d1)
      if (phase1_str == d2_ptr%d1(i)%name) d1_x => d2_ptr%d1(i)
      if (phase2_str == d2_ptr%d1(i)%name) d1_y => d2_ptr%d1(i)
    enddo
    if (.not. associated(d1_x)) then
      call out_io (s_error$, r_name, &
              'CANNOT FIND DATA FOR PHASE SPACE COORDINATE: ' // phase1_str, &
              'FOR CURVE: ' // curve%name)
      call err_exit
    endif
    if (.not. associated(d1_y)) then
      call out_io (s_error$, r_name, &
              'CANNOT FIND DATA FOR PHASE SPACE COORDINATE: ' // phase2_str, &
              'FOR CURVE: ' // curve%name)
      call err_exit
    endif

    if (lbound(d1_x%d, 1) /= lbound(d1_y%d, 1) .or. &
                                        ubound(d1_x%d, 1) /= ubound(d1_y%d, 1)) then 
      call out_io (s_error$, r_name, &
              'BOUNDS FOR X-AXIS AND Y-AXIS DATA OF PHASE SPACE PLOTTING MISMATCHED.', &
              'FOR CURVE: ' // curve%name)
      call err_exit
    endif

    n = size(d1_x%d)
    call re_allocate (curve%ix_symb, n)
    call re_allocate (curve%x_symb, n)
    call re_allocate (curve%y_symb, n)

    do ib = 1, n
      i = ib + lbound(d1_x%d, 1) - 1
      curve%x_symb(ib) = d1_x%d(i)%model_value
      curve%y_symb(ib) = d1_y%d(i)%model_value
    enddo


  elseif (curve%data_source == 'twiss') then

    n = 2 * s%global%n_curve_pts
    call re_allocate (curve%x_line, n)
    call re_allocate (curve%y_line, n)

    call make_v_mats (ele, v_mat, v_inv_mat)
    call make_g_mats (ele, g_mat, g_inv_mat)

    mat4 = matmul(v_mat, g_inv_mat)
    sigma_mat =  0
    sigma_mat(1,1) = u%model%lat%x%emit
    sigma_mat(2,2) = u%model%lat%x%emit
    sigma_mat(3,3) = u%model%lat%y%emit
    sigma_mat(4,4) = u%model%lat%y%emit
    sigma_mat = matmul (matmul (mat4, sigma_mat), transpose(mat4))

    if (ix1_ax > 4 .or. ix2_ax > 4) then
      call out_io (s_error$, r_name, &
        'Z OR P_Z PHASE SPACE PLOTTING NOT YET IMPLEMENTED FOR "twiss" DATA_SOURCE.')
      return
    endif

    rx = sqrt(sigma_mat(ix1_ax, ix1_ax))
    ry = sqrt(sigma_mat(ix2_ax, ix2_ax))
    write (graph%legend(1), '(a, f10.6)') 'r_x:', rx
    write (graph%legend(2), '(a, f10.6)') 'r_y:', ry

    if(rx == 0 .or. ry == 0) then
      theta_xy = 0
      write (graph%legend(3), '(a, f10.4)') 'Theta_tilt (rad):', 0
    else
      theta_xy =  asin(sigma_mat(ix1_ax, ix2_ax) / (rx * ry))
      phi = 0.5 *atan2((rx**2+ry**2) * sin(2*theta_xy), &
                              (rx**2-ry**2) * cos(2*theta_xy)) - theta_xy
      write (graph%legend(3), '(a, f10.4)') 'Theta_tilt (rad):', phi
  endif

    n = 2 * s%global%n_curve_pts
    call re_allocate (curve%x_line, n)
    call re_allocate (curve%y_line, n)

    do i = 1, n
      theta = (i-1) * twopi / (n-1)
      curve%x_line(i) = rx * cos(theta)
      curve%y_line(i) = ry * sin(theta + theta_xy)
    enddo

  else
    call out_io (s_abort$, r_name, &
        'INVALID CURVE%DATA_SOURCE: ' // curve%data_source, &
        'FOR CURVE: '// curve%name)
    call err_exit
  endif

enddo

graph%valid = .true.

end subroutine

!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!----------------------------------------------------------------------------

subroutine tao_phase_space_axis (data_type, ix_axis, err)

use tao_mod

implicit none

character(*) data_type
integer ix_axis
logical err
character(16) :: r_name = 'phase_space_axis'

!

select case (data_type)
case ('x');   ix_axis = 1
case ('p_x'); ix_axis = 2
case ('y');   ix_axis = 3
case ('p_y'); ix_axis = 4
case ('z');   ix_axis = 5
case ('p_z'); ix_axis = 6
case default
  call out_io (s_abort$, r_name, 'BAD PHASE_SPACE CURVE DATA_TYPE: ' // data_type)
  call err_exit
  err = .true.
end select

end subroutine

!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!----------------------------------------------------------------------------

subroutine tao_data_plot_data_setup (plot, graph)

use tao_data_mod
use tao_mod

implicit none

type (tao_plot_struct) plot
type (tao_graph_struct), target :: graph
type (tao_curve_struct), pointer :: curve
type (tao_universe_struct), pointer :: u
type (tao_d2_data_struct), pointer :: d2_ptr
type (tao_d1_data_struct), pointer :: d1_ptr
type (tao_v1_var_struct) , pointer :: v1_ptr
type (tao_data_struct) datum
type (taylor_struct) t_map(6)
type (tao_var_struct), pointer :: v_ptr

real(rp) f, y_val, eps, gs
real(rp), pointer :: value(:)

integer ii, k, m, n_dat, i_uni, ie, jj, iv, ic
integer ix, ir, jg, i, i_max, i_min, ix_this
integer, allocatable, save :: ix_ele(:)

logical err, smooth_curve, found, zero_average_phase

character(12)  :: u_view_char
character(30) :: r_name = 'tao_data_plot_data_setup'
character(40) track_type

call reallocate_integer (ix_ele, 1)

! For the title_suffix: strip off leading "+" and enclose in "[ ]".

graph%title_suffix = ' '
do m = 1, size(graph%who)
  if (graph%who(m)%name == ' ') cycle
  if (graph%who(m)%sign == 1) then
    graph%title_suffix = trim(graph%title_suffix) // ' + ' // graph%who(m)%name
  elseif (graph%who(m)%sign == -1) then
    graph%title_suffix = trim(graph%title_suffix) // ' - ' // graph%who(m)%name
  endif
enddo

if (graph%title_suffix(2:2) == '+') graph%title_suffix = graph%title_suffix(4:)

graph%title_suffix = '[' // trim(graph%title_suffix) // ']'

! attach x-axis type to title suffix 
 
 if (plot%x_axis_type == 'index') then
   graph%title_suffix = trim(graph%title_suffix) // ', X-axis: index, '
 elseif (plot%x_axis_type == 'ele_index') then
   graph%title_suffix = trim(graph%title_suffix) // ', X-axis: ele_index, '
 elseif (plot%x_axis_type == 's') then
   graph%title_suffix = trim(graph%title_suffix) // ', X-axis: s, '
 endif  

!-------------------------------------------------------------------------------
! Loop over all curves in the graph

do k = 1, size(graph%curve)

  curve => graph%curve(k)

  i_uni = s%global%u_view  ! universe where the data comes from
  if (curve%ix_universe /= 0) i_uni = curve%ix_universe 
  u => s%u(i_uni)

  if (curve%ele_ref_name == ' ') then
    zero_average_phase = .true.
    curve%ix_ele_ref = 0
  else
    zero_average_phase = .false.
    call tao_locate_element (curve%ele_ref_name, i_uni, ix_ele, .true.)
    if (ix_ele(1) < 0) then
      graph%valid = .false.
      return
    endif
    curve%ix_ele_ref = ix_ele(1)
  endif



!----------------------------------------------------------------------------
! Calculate where the symbols are to be drawn on the graph.

  select case (curve%data_source)

!----------------------------------------------------------------------------
! Case: data_source is a data array

  case ('data_array')
    call tao_find_data (err, curve%data_type, d2_ptr, d1_ptr, ix_uni = i_uni)
    if (err) then
      call out_io (s_error$, r_name, &
                'CANNOT FIND DATA ARRAY TO PLOT CURVE: ' // curve%data_type)
      graph%valid = .false.
      return
    endif

    if (d2_ptr%name == 'phase') then
      if (all(d1_ptr%d%ele0_name == ' ')) then
        zero_average_phase = .true.
      else
        zero_average_phase = .false.
      endif
    endif

    d1_ptr%d%good_plot = .true.
    if (plot%x%min /= plot%x%max) then
      eps = 1e-4 * (plot%x%max - plot%x%min)
      if (plot%x_axis_type == 'index') then
        where (d1_ptr%d%ix_d1 < plot%x%min-eps) d1_ptr%d%good_plot = .false.
        where (d1_ptr%d%ix_d1 > plot%x%max+eps) d1_ptr%d%good_plot = .false.
      elseif (plot%x_axis_type == 'ele_index') then
        where (d1_ptr%d%ix_ele < plot%x%min-eps) d1_ptr%d%good_plot = .false.
        where (d1_ptr%d%ix_ele > plot%x%max+eps) d1_ptr%d%good_plot = .false.
      else ! s
        where (d1_ptr%d%s < plot%x%min-eps) d1_ptr%d%good_plot = .false.
        where (d1_ptr%d%s > plot%x%max+eps) d1_ptr%d%good_plot = .false.
      endif
    endif

    ! make sure %useit_plot up-to-date & count the number of data points
    call tao_data_useit_plot_calc (graph, d1_ptr%d) 
    if (plot%x_axis_type == 's') then
      ! veto non-regular elements when plotting s
      forall (m = lbound(d1_ptr%d,1):ubound(d1_ptr%d,1), &
                     d1_ptr%d(m)%ix_ele .gt. u%model%lat%n_ele_use)
        d1_ptr%d(m)%useit_plot = .false.
      endforall
    endif
    n_dat = count (d1_ptr%d%useit_plot)       

    call re_allocate (curve%ix_symb, n_dat)
    call re_allocate (curve%y_symb, n_dat) ! allocate space for the data
    call re_allocate (curve%x_symb, n_dat) ! allocate space for the data

    curve%ix_symb = pack(d1_ptr%d%ix_d1, mask = d1_ptr%d%useit_plot)

    if (plot%x_axis_type == 'index') then
      curve%x_symb = curve%ix_symb
    elseif (plot%x_axis_type == 'ele_index') then
      curve%x_symb = d1_ptr%d(curve%ix_symb)%ix_ele
    elseif (plot%x_axis_type == 's') then
      curve%x_symb = u%model%lat%ele_(d1_ptr%d(curve%ix_symb)%ix_ele)%s
    else
      call out_io (s_error$, r_name, "Unknown axis type!")
      graph%valid = .false.
      return
    endif

! calculate the y-axis data point values.

    curve%y_symb = 0

    do m = 1, size(graph%who)
      select case (graph%who(m)%name)
      case (' ') 
        cycle
      case ('model') 
        value => d1_ptr%d%model_value
      case ('base')  
        value => d1_ptr%d%base_value
      case ('design')  
        value => d1_ptr%d%design_value
      case ('ref')     
        value => d1_ptr%d%ref_value
      case ('meas')    
        value => d1_ptr%d%meas_value
      case default
        call out_io (s_error$, r_name, 'BAD PLOT "WHO": ' // graph%who(m)%name)
        graph%valid = .false.
        return
      end select
      curve%y_symb = curve%y_symb + &
                   graph%who(m)%sign * pack(value, mask = d1_ptr%d%useit_plot)
    enddo

    if (curve%convert) curve%y_symb = curve%y_symb * &
                           pack(d1_ptr%d%conversion_factor, d1_ptr%d%useit_plot)


!----------------------------------------------------------------------------
! Case: data_source is a var array

  case ('var_array')
    call tao_find_var (err, curve%data_type, v1_ptr)
    if (err) then
      graph%valid = .false.
      return
    endif

    ! find which universe we're viewing
    ix_this = -1
    v_loop: do iv = lbound(v1_ptr%v, 1), ubound(v1_ptr%v,1)
      v_ptr => v1_ptr%v(iv)
      if (.not. v_ptr%exists) cycle
      do jj = 1, size(v_ptr%this)
        if (v_ptr%this(jj)%ix_uni .eq. s%global%u_view) then
          ix_this = jj
          exit v_loop
        endif
      enddo
    enddo v_loop
    if (ix_this .eq. -1) then
      call out_io (s_error$, r_name, &
                     "This variable doesn't point to the currently displayed  universe.")
      graph%valid = .false.
      return
    endif

    v1_ptr%v%good_plot = .true.
    if (plot%x%min /= plot%x%max) then
      eps = 1e-4 * (plot%x%max - plot%x%min)
      if (plot%x_axis_type == 'index') then
        where (v1_ptr%v%ix_v1 < plot%x%min-eps) v1_ptr%v%good_plot = .false.
        where (v1_ptr%v%ix_v1 > plot%x%max+eps) v1_ptr%v%good_plot = .false.
      elseif (plot%x_axis_type == 'ele_index') then
        do jj = lbound(v1_ptr%v, 1), ubound(v1_ptr%v,1)
          if (v1_ptr%v(jj)%this(ix_this)%ix_ele < plot%x%min-eps) v1_ptr%v%good_plot = .false.
          if (v1_ptr%v(jj)%this(ix_this)%ix_ele > plot%x%max+eps) v1_ptr%v%good_plot = .false.
        enddo
      else
        where (v1_ptr%v%s < plot%x%min-eps) v1_ptr%v%good_plot = .false.
        where (v1_ptr%v%s > plot%x%max+eps) v1_ptr%v%good_plot = .false.
      endif
    endif

    call tao_var_useit_plot_calc (graph, v1_ptr%v) ! make sure %useit_plot up-to-date
    n_dat = count (v1_ptr%v%useit_plot)       ! count the number of data points

    call re_allocate (curve%ix_symb, n_dat)
    call re_allocate (curve%y_symb, n_dat) ! allocate space for the data
    call re_allocate (curve%x_symb, n_dat) ! allocate space for the data

    curve%ix_symb = pack(v1_ptr%v%ix_v1, mask = v1_ptr%v%useit_plot)

    plot%x%label = plot%x_axis_type

    if (plot%x_axis_type == 'index') then
      curve%x_symb = curve%ix_symb
    elseif (plot%x_axis_type == 'ele_index') then
      do jj = lbound(curve%ix_symb,1), ubound(curve%ix_symb,1)
        curve%x_symb(jj) = v1_ptr%v(curve%ix_symb(jj))%this(ix_this)%ix_ele
      enddo
    elseif (plot%x_axis_type == 's') then
      do jj = lbound(curve%ix_symb,1), ubound(curve%ix_symb,1)
        curve%x_symb(jj) = u%model%lat%ele_(v1_ptr%v(curve%ix_symb(jj))%this(ix_this)%ix_ele)%s
      enddo
    endif

! calculate the y-axis data point values.

    curve%y_symb = 0

    do m = 1, size(graph%who)

      gs = graph%who(m)%sign

      select case (graph%who(m)%name)
      case (' ') 
        cycle

      ! set value to whatever it is in currently viewed universe
      case ('model') 
        ic = 0
        do jj = lbound(v1_ptr%v,1), ubound(v1_ptr%v,1)
          v_ptr => v1_ptr%v(jj)
          if (.not. v_ptr%useit_plot) cycle
          ic = ic + 1
          curve%y_symb(ic) = curve%y_symb(ic) + gs * v_ptr%this(ix_this)%model_ptr
        enddo
        cycle

      ! set value to whatever it is in currently viewed universe
      case ('base')  
        ic = 0
        do jj = lbound(v1_ptr%v,1), ubound(v1_ptr%v,1)
          v_ptr => v1_ptr%v(jj)
          if (.not. v_ptr%useit_plot) cycle
          ic = ic + 1
          curve%y_symb(ic) = curve%y_symb(ic) + gs * v_ptr%this(ix_this)%base_ptr
        enddo
        cycle

      case ('design')  
        value => v1_ptr%v%design_value
      case ('ref')     
        value => v1_ptr%v%ref_value
      case ('meas')    
        value => v1_ptr%v%meas_value
      case default
        call out_io (s_error$, r_name, 'BAD PLOT "WHO": ' // graph%who(m)%name)
        graph%valid = .false.
        return
      end select

      curve%y_symb = curve%y_symb + gs * pack(value, mask = v1_ptr%v%useit_plot)

    enddo

    if (curve%convert) curve%y_symb = curve%y_symb * &
                           pack(v1_ptr%v%conversion_factor, v1_ptr%v%useit_plot)


!----------------------------------------------------------------------------
! Case: data source is from the lattice_layout

  case ('calculation', 'beam_tracking')

    if (plot%x_axis_type == 'index' .or. plot%x_axis_type == 'ele_index') then
      i_min = 1
      i_max = u%base%lat%n_ele_use
      if (plot%x%min /= plot%x%max) then
        i_min = max(i_min, floor(plot%x%min))
        i_max = min(i_max, ceiling(plot%x%max))
      endif 
      n_dat = max(0, i_max+1-i_min)
    elseif (plot%x_axis_type == 's') then
      ! %ix_pointer has been set to the element index for displayed elements
      eps = 1e-4 * (plot%x%max - plot%x%min)             ! a small number
      u%base%lat%ele_(:)%logic = (u%base%lat%ele_(:)%ix_pointer > 0)
      if (plot%x%min /= plot%x%max) then
        u%base%lat%ele_(:)%logic = u%base%lat%ele_(:)%logic .and. &
                                 (u%base%lat%ele_(:)%s >= plot%x%min-eps) .and. &
                                 (u%base%lat%ele_(:)%s <= plot%x%max+eps)
      endif
      n_dat = count (u%base%lat%ele_(:)%logic)
    endif

    call re_allocate (curve%ix_symb, n_dat)
    call re_allocate (curve%y_symb, n_dat) ! allocate space for the data
    call re_allocate (curve%x_symb, n_dat) ! allocate space for the data


    if (plot%x_axis_type == 'index' .or. plot%x_axis_type == 'ele_index') then
      if (n_dat > 0) curve%ix_symb = (/ (i, i = i_min, i_max) /)
      curve%x_symb = curve%ix_symb
    elseif (plot%x_axis_type == 's') then
      curve%ix_symb = pack(u%base%lat%ele_(:)%ix_pointer, &
                                                  mask = u%base%lat%ele_(:)%logic)
      curve%x_symb = u%model%lat%ele_(curve%ix_symb)%s
    endif

    ! calculate the y-axis data point values.

    curve%y_symb = 0
    datum%ix_ele0 = curve%ix_ele_ref
    datum%merit_type = 'target'
    datum%data_type = curve%data_type
    datum%ele0_name = curve%ele_ref_name
    if (curve%data_source == 'calculation') then
      track_type = 'single'
    else
      track_type = s%global%track_type
    endif

    do m = 1, size(graph%who)
      do ie = 1, n_dat

        datum%ix_ele = curve%ix_symb(ie)

        if (datum%data_type(1:3) == 'tt.' .or. datum%data_type(1:2) == 't.') then
          if (ie == 1) call taylor_make_unit (t_map)
        endif

        select case (graph%who(m)%name)
        case (' ') 
          cycle
        case ('model')   
          call tao_evaluate_a_datum (datum, u, u%model, track_type, y_val, t_map)
        case ('base')  
          call tao_evaluate_a_datum (datum, u, u%base, track_type, y_val, t_map)
        case ('design')  
          call tao_evaluate_a_datum (datum, u, u%design, track_type, y_val, t_map)
        case default
          call out_io (s_error$, r_name, &
                  'BAD PLOT "WHO" FOR DATA_SOURCE: ' // graph%who(m)%name, &
                  '    FOR DATA_TYPE: ' // curve%data_type)
          graph%valid = .false.
          return
        end select
        curve%y_symb(ie) = curve%y_symb(ie) + graph%who(m)%sign * y_val

        if (datum%data_type(1:3) == 'tt.' .or. datum%data_type(1:2) == 't.') then
          if (datum%ix_ele < datum%ix_ele0) datum%ix_ele0 = datum%ix_ele
        endif

      enddo
    enddo

!----------------------------------------------------------------------------
! Case: Bad data_source

  case default
    call out_io (s_error$, r_name, 'UNKNOWN DATA_SOURCE: ' // curve%data_source)
    graph%valid = .false.
    return
  end select

!----------------------------------------------------------------------------
! Now calculate the points for drawing the curve through the symbols.
! If the x-axis is by index or ele_index then these points are the same as the symbol points.
! That is, for x-axis = index or ele_index the line is piece-wise linear between the symbols.
! If the axis is by s-value then the line is a "smooth" curve with n_curve_pts points if
! plotting model, base or design data. It's the same as the symbol points otherwise.
! Smoothing will only be performed if performing single particle tracking.

  select case (plot%x_axis_type)
  case ('index')
    call re_allocate (curve%y_line, n_dat) ! allocate space for the data
    call re_allocate (curve%x_line, n_dat) ! allocate space for the data
    curve%x_line = curve%x_symb
    curve%y_line = curve%y_symb

  case ('ele_index')
    call re_allocate (curve%y_line, n_dat) ! allocate space for the data
    call re_allocate (curve%x_line, n_dat) ! allocate space for the data
    curve%x_line = curve%x_symb
    curve%y_line = curve%y_symb

  case ('s')

    smooth_curve = (curve%data_source == 'calculation') .or. &
                   (s%global%track_type == 'single') .or. &
                   (s%global%track_type == 'beam' .and. allocated(u%model%bunch_params2))
    smooth_curve = smooth_curve .and. curve%draw_interpolated_curve
    do m = 1, size(graph%who)
      if (graph%who(m)%name == 'meas' .or. graph%who(m)%name == 'ref') smooth_curve = .false.
    enddo

    if (smooth_curve) then

      ! allocate data space

      call re_allocate (curve%y_line, s%global%n_curve_pts) 
      call re_allocate (curve%x_line, s%global%n_curve_pts) 
      curve%y_line = 0

      do m = 1, size(graph%who)
        select case (graph%who(m)%name)
        case (' ') 
          cycle
        case ('model')
          call calc_data_at_s (u%model, curve, graph%who(m), err)
        case ('base')  
          call calc_data_at_s (u%base, curve, graph%who(m), err)
        case ('design')  
          call calc_data_at_s (u%design, curve, graph%who(m), err)
        case default
          call out_io (s_error$, r_name, &
                       'BAD PLOT "WHO" WITH "S" X-AXIS: ' // graph%who(m)%name)
          graph%valid = .false.
          return
        end select
        if (err) then
          graph%valid = .false.
          return
        endif
      enddo

    endif

    if (.not. smooth_curve) then
      ! allocate space for the data
      call re_allocate (curve%y_line, n_dat) 
      call re_allocate (curve%x_line, n_dat) 
      curve%x_line = curve%x_symb 
      curve%y_line = curve%y_symb 
    endif

  end select

!----------------------------------------------------------------------------
! Note: Since there is an arbitrary overall phase, the phase data 
! gets renormalized so that the average value is zero.

  if (curve%data_type(1:6) == 'phase.' .and. n_dat /= 0 .and. zero_average_phase) then
    f = sum(curve%y_symb) / n_dat
    curve%y_symb = curve%y_symb - f
    curve%y_line = curve%y_line - f 
  endif 

enddo

!----------------------------------------------------------------------------
contains 

subroutine calc_data_at_s (tao_lat, curve, who, err)

type (tao_lattice_struct), target :: tao_lat
type (tao_plot_who_struct) who
type (tao_curve_struct) curve
type (bunch_params_struct), pointer :: bunch_params
type (coord_struct), pointer :: orb(:)
type (coord_struct), pointer :: orb0
type (ring_struct), pointer :: lat
type (ele_struct) ele
type (ele_struct), pointer :: ele0
type (coord_struct) here
type (taylor_struct) t_map(6)

real(rp) x1, x2, cbar(2,2), s_last, s_now, value, mat6(6,6)
real(rp) eta_vec(4), v_mat(4,4), v_inv_mat(4,4), one_pz, gamma

integer i, j, k, expnt(6), ix_ele, ix0
character(40) data_type
character(40) data_type_select, track_type
character(20) ::r_name = 'calc_data_at_s'
logical err

!

err = .false.

data_type = curve%data_type

lat => tao_lat%lat
orb => tao_lat%orb
ix0 = curve%ix_ele_ref
if (ix0 < 0) ix0 = 0

if (lat%param%lattice_type == circular_lattice$ .and. .not. lat%param%stable) then
  err = .true.
  return
endif

if (curve%data_source == 'calculation') then
  track_type = 'single'
else
  track_type = s%global%track_type
endif

x1 = u%model%lat%ele_(0)%s
x2 = u%model%lat%ele_(u%model%lat%n_ele_use)%s
if (plot%x%min /= plot%x%max) then
  x1 = min(u%model%lat%ele_(u%model%lat%n_ele_use)%s, max(plot%x%min, x1))
  x2 = min(x2, max(plot%x%max, u%model%lat%ele_(0)%s))
endif
ele0 => lat%ele_(ix0)
orb0 => orb(ix0)
s_last = ele0%s

data_type_select = data_type
if (data_type_select(1:2) == 'r.') data_type_select = 'r.'
if (data_type_select(1:2) == 't.') data_type_select = 't.'
if (data_type_select(1:3) == 'tt.') data_type_select = 'tt.'

!

do ii = 1, size(curve%x_line)

  s_now = x1 + (ii-1) * (x2-x1) / (size(curve%x_line)-1)
  if (s_now .ge. lat%ele_(lat%n_ele_use)%s) s_now = lat%ele_(lat%n_ele_use)%s - 1e-9
  curve%x_line(ii) = s_now
  value = 0

  select case (track_type)
  case ('single')   
    call twiss_and_track_at_s (lat, s_now, ele, orb, here)
  case ('beam')
    call find_nearest_bunch_params (tao_lat, s_now, bunch_params)
    call ele_at_s (lat, s_now, ix_ele)
    ele = lat%ele_(ix_ele)
    here = bunch_params%centroid
  case default
    call out_io (s_fatal$, r_name, &
            'I DO NOT KNOW HOW TO HANDLE THIS TRACK TYPE: ' // track_type)
    call err_exit
  end select

!

  select case (data_type_select)
  case ('orbit.x')
    value = here%vec(1)
  case ('orbit.y')
    value = here%vec(3)
  case ('orbit.z')
    value = here%vec(5)
  case ('orbit.p_x')
    value = here%vec(2)
  case ('orbit.p_y')
    value = here%vec(4)
  case ('orbit.p_z')
    value = here%vec(6)
  case ('phase.x')
    value = ele%x%phi
  case ('phase.y')
    value = ele%y%phi
  case ('beta.x', 'beta.a')
    value = ele%x%beta
  case ('beta.y', 'beta.b')
    value = ele%y%beta
  case ('alpha.x', 'alpha.a')
    value = ele%x%alpha
  case ('alpha.y', 'alpha.b')
    value = ele%y%alpha
  case ('eta.x')
    value = ele%x%eta_lab
  case ('eta.y')
    value = ele%y%eta_lab
  case ('etap.x')
    value = ele%x%etap_lab
  case ('etap.y')
    value = ele%y%etap_lab
  case ('eta.a')
    value = ele%x%eta
  case ('eta.b')
    value = ele%y%eta
  case ('etap.a')
    value = ele%x%etap
  case ('etap.b')
    value = ele%y%etap
  case ('floor.x')
    value = ele%floor%x
  case ('floor.y')
    value = ele%floor%y
  case ('floor.z')
    value = ele%floor%z
  case ('beam_energy')
    value = ele%value(beam_energy$) * (1 + here%vec(6))
  case ('%beam_energy')
    value = here%vec(6)
  case ('cbar.11')
    call c_to_cbar (ele, cbar)
    value = cbar(1,1)
  case ('cbar.12')
    call c_to_cbar (ele, cbar)
    value = cbar(1,2)
  case ('cbar.21')
    call c_to_cbar (ele, cbar)
    value = cbar(2,1)
  case ('cbar.22')
    call c_to_cbar (ele, cbar)
    value = cbar(2,2)
  case ('coupling.11b')
    call c_to_cbar (ele, cbar)
    value = cbar(1,1) * sqrt(ele%x%beta/ele%y%beta) / ele%gamma_c
  case ('coupling.12a')
    call c_to_cbar (ele, cbar)
    value = cbar(1,2) * sqrt(ele%y%beta/ele%x%beta) / ele%gamma_c
  case ('coupling.12b')
    call c_to_cbar (ele, cbar)
    value = cbar(1,2) * sqrt(ele%x%beta/ele%y%beta) / ele%gamma_c
  case ('coupling.22a')
    call c_to_cbar (ele, cbar)
    value = cbar(2,2)* sqrt(ele%y%beta/ele%x%beta) / ele%gamma_c
  case ('sigma.x')
    value = sqrt(bunch_params%sigma(s11$))
  case ('sigma.p_x')
    value = sqrt(bunch_params%sigma(s22$))
  case ('sigma.y')
    value = sqrt(bunch_params%sigma(s33$))
  case ('sigma.p_y')
    value = sqrt(bunch_params%sigma(s44$))
  case ('sigma.z')
    value = sqrt(bunch_params%sigma(s55$))
  case ('sigma.p_z')
    value = sqrt(bunch_params%sigma(s66$))
  case ('norm_emittance.x')
    value = bunch_params%x%norm_emitt
  case ('norm_emittance.y')
    value = bunch_params%y%norm_emitt
  case ('norm_emittance.z')
    value = bunch_params%z%norm_emitt
  case ('emittance.x')
    value = bunch_params%x%norm_emitt
    call convert_total_energy_to (ele%value(beam_energy$), &
                                              lat%param%particle, gamma)
    value = value / gamma
  case ('emittance.y')
    value = bunch_params%y%norm_emitt
    call convert_total_energy_to (ele%value(beam_energy$), &
                                              lat%param%particle, gamma)
    value = value / gamma
  case ('r.')
    if (ii == 1) call mat_make_unit (mat6)
    if (s_now < s_last) cycle
    i = tao_read_this_index (data_type, 3); if (i == 0) return
    j = tao_read_this_index (data_type, 4); if (j == 0) return
    call tao_mat6_calc_at_s (lat, mat6, s_last, s_now, unit_start = .false.)
    value = mat6(i, j)
  case ('t.')
    if (ii == 1) call taylor_make_unit (t_map)
    if (s_now < s_last) cycle
    i = tao_read_this_index (data_type, 3); if (i == 0) return
    j = tao_read_this_index (data_type, 4); if (j == 0) return
    k = tao_read_this_index (data_type, 5); if (k == 0) return
    call tao_transfer_map_calc_at_s (lat, t_map, s_last, s_now, unit_start = .false.)
    value = taylor_coef (t_map(i), j, k)
  case ('tt.')
    if (ii == 1) call taylor_make_unit (t_map)
    if (s_now < s_last) cycle
    expnt = 0
    i = tao_read_this_index (data_type, 4); if (i == 0) return
    do j = 5, 15
      if (data_type(j:j) == ' ') exit
      k = tao_read_this_index (data_type, j); if (k == 0) return
      expnt(k) = expnt(k) + 1
    enddo
    call tao_transfer_map_calc_at_s (lat, t_map, s_last, s_now, unit_start = .false.)
    value = taylor_coef (t_map(i), expnt)
  case ('momentum_compaction')
    call tao_mat6_calc_at_s (lat, mat6, s_last, s_now, unit_start = .false.)
    call make_v_mats (ele0, v_mat, v_inv_mat)
    eta_vec = (/ ele0%x%eta, ele0%x%etap, ele0%y%eta, ele0%y%etap /)
    eta_vec = matmul (v_mat, eta_vec)
    one_pz = 1 + orb0%vec(6)
    eta_vec(2) = eta_vec(2) * one_pz + orb0%vec(2) / one_pz
    eta_vec(4) = eta_vec(4) * one_pz + orb0%vec(4) / one_pz
    value = sum(mat6(5,1:4) * eta_vec) + mat6(5,6)

  case default
   call out_io (s_fatal$, r_name, &
                  'DO NOT KNOW ABOUT THIS DATA_TYPE: ' // data_type)
   call out_io (s_blank$, r_name, "Will not perfrom any plot smoothing")
    err = .true.
    return
  end select

  curve%y_line(ii) = curve%y_line(ii) + who%sign * value
  s_last = s_now

enddo

end subroutine

!----------------------------------------------------------------------------
! contains 

subroutine find_nearest_bunch_params (tao_lat, s, bunch_params)

type (tao_lattice_struct), target :: tao_lat
type (bunch_params_struct), pointer :: bunch_params
real(rp) s
integer ix

!

if (.not. allocated(tao_lat%bunch_params2)) then
  call out_io (s_fatal$, r_name, 'BUNCH_PARAMS2 NOT ALLOCATED.')
  call err_exit
endif

call bracket_index (tao_lat%bunch_params2(:)%s, 1, tao_lat%n_bunch_params2, s, ix)
if (abs(tao_lat%bunch_params2(ix)%s - s) < abs(tao_lat%bunch_params2(ix+1)%s - s)) then
  bunch_params => tao_lat%bunch_params2(ix)
else
  bunch_params => tao_lat%bunch_params2(ix+1)
endif

end subroutine

end subroutine


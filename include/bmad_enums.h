
#ifndef BMAD_ENUMS

namespace Bmad {
  const int BMAD_INC_VERSION = 132;
  const int NUM_ELE_ATTRIB = 70;
  const int OFF = 1, ON = 2;
  const int BRAGG_DIFFRACTED = 1, FORWARD_DIFFRACTED = 2, UNDIFFRACTED = 3;
  const int REFLECTION = 1, TRANSMISSION = 2;
  const int ANCHOR_BEGINNING = 1, ANCHOR_CENTER = 2, ANCHOR_END = 3;
  const int ENTRANCE_END = 1, EXIT_END = 2, BOTH_ENDS = 3, NO_END = 4;
  const int CONTINUOUS = 5, SURFACE = 6;
  const int FIRST_TRACK_EDGE = 11, SECOND_TRACK_EDGE = 12;
  const int UPSTREAM_END = 1, DOWNSTREAM_END = 2;
  const int INSIDE = 3, CENTER_PT = 3;
  const int NORMAL = 1, CLEAR = 2, MASK = 3, TRUNK = 4, TRUNK1 = 5;
  const int TRUNK2 = 6, LEG1 = 7, LEG2 = 8;
  const int X_PLANE = 1, Y_PLANE = 2;
  const int Z_PLANE = 3, N_PLANE = 4, S_PLANE = 5;
  const int MOVING_FORWARD = -9;
  const int ALIVE = 1, LOST = 2;
  const int LOST_NEG_X_APERTURE = 3, LOST_POS_X_APERTURE = 4;
  const int LOST_NEG_Y_APERTURE = 5, LOST_POS_Y_APERTURE = 6;
  const int LOST_Z_APERTURE = 7;
  const int HYPER_Y = 1, HYPER_XY = 2, HYPER_X = 3;
  const int SUPER_OK = 0, STALE = 2;
  const int ATTRIBUTE_GROUP = 1, CONTROL_GROUP = 2, FLOOR_POSITION_GROUP = 3;
  const int S_POSITION_GROUP = 4, REF_ENERGY_GROUP = 5, MAT6_GROUP = 6;
  const int RAD_INT_GROUP = 7, ALL_GROUPS = 8;
  const int SEGMENTED = 2, H_MISALIGN = 3;
  const int INCOHERENT = 1, COHERENT = 2;
  const int OPAL = 1, IMPACTT = 2;
  const int DRIFT = 1, SBEND = 2, QUADRUPOLE = 3, GROUP = 4;
  const int SEXTUPOLE = 5, OVERLAY = 6, CUSTOM = 7, TAYLOR = 8;
  const int RFCAVITY = 9;
  const int ELSEPARATOR = 10, BEAMBEAM = 11, WIGGLER = 12;
  const int SOL_QUAD = 13, MARKER = 14, KICKER = 15;
  const int HYBRID = 16, OCTUPOLE = 17, RBEND = 18;
  const int MULTIPOLE = 19, KEY_DUMMY = 20;
  const int DEF_BEAM = 21, AB_MULTIPOLE = 22, SOLENOID = 23;
  const int PATCH = 24, LCAVITY = 25, DEF_PARAMETER = 26;
  const int NULL_ELE = 27, INIT_ELE = 28, HOM = 29;
  const int MATCH = 30, MONITOR = 31, INSTRUMENT = 32;
  const int HKICKER = 33, VKICKER = 34, RCOLLIMATOR = 35;
  const int ECOLLIMATOR = 36, GIRDER = 37, BEND_SOL_QUAD = 38;
  const int DEF_BEAM_START = 39, PHOTON_BRANCH = 40;
  const int BRANCH = 41, MIRROR = 42, CRYSTAL = 43;
  const int PIPE = 44, CAPILLARY = 45, MULTILAYER_MIRROR = 46;
  const int E_GUN = 47, EM_FIELD = 48, FLOOR_SHIFT = 49, FIDUCIAL = 50;
  const int UNDULATOR = 51, DIFFRACTION_PLATE = 52;
  const int X_RAY_INIT = 53, SAMPLE = 54, DETECTOR = 55;
  const int N_KEY = 55;
  const int N_PART = 2, TAYLOR_ORDER = 3;
  const int VAL1=3, VAL2=4, VAL3=5, VAL4=6, VAL5=7,
            VAL6=9, VAL7=10, VAL8=11, VAL9=12, VAL10=13, VAL11=14,
            VAL12=15;
  const int BETA_A0 = 2, ALPHA_A0 = 3, BETA_B0 = 4,
            ALPHA_B0 = 5, BETA_A1 = 6, ALPHA_A1 = 7, BETA_B1 = 8,
            ALPHA_B1 = 9, DPHI_A = 10, DPHI_B = 11,
            ETA_X0 = 12, ETAP_X0 = 13, ETA_Y0 = 14, ETAP_Y0 = 15,
            ETA_X1 = 16, ETAP_X1 = 17, ETA_Y1 = 18, ETAP_Y1 = 19,
            MATCH_END = 20,
            X0 = 21, PX0 = 22, Y0 = 23, PY0 = 24, Z0 = 25, PZ0 = 26,
            X1 = 27, PX1 = 28, Y1 = 29, PY1 = 30, Z1 = 31, PZ1 = 32,
            MATCH_END_ORBIT = 33, C_11 = 34, C_12 = 35, C_21 = 36, C_22 = 37, GAMMA_C = 39;
  const int X = 1, PX = 2, Y = 3, PY = 4, Z = 5, PZ = 6;
  const int T = 8;
  const int FIELD_X = 10, FIELD_Y = 11, PHASE_X = 12, PHASE_Y = 13;
  const int E_PHOTON = 14;
  const int X_BEAM_START = 1, PX_BEAM_START = 2, Y_BEAM_START = 3;
  const int PY_BEAM_START = 4, Z_BEAM_START = 5, PZ_BEAM_START = 6;
  const int ABS_TIME_START = 8;
  const int L=1;
  const int TILT=2, COMMAND=2, ROLL=2;
  const int REF_TILT = 3, RF_FREQUENCY=3, DIRECTION=3;
  const int OLD_COMMAND=3, KICK=3, X_GAIN_ERR=3;
  const int RF_FREQUENCY_ERR=4, K1=4, SIG_X=4, HARMON=4, H_DISPLACE=4, Y_GAIN_ERR=4;
  const int CRITICAL_ANGLE_FACTOR = 4, TILT_CORR = 4, REF_COORDINATES = 4;
  const int LR_FREQ_SPREAD=5, GRAZE_ANGLE=5, K2=5, SIG_Y=5, B_MAX=5, V_DISPLACE=5;
  const int FLEXIBLE = 5, CRUNCH=5, REF_ORBIT_FOLLOWS=5;
  const int GRADIENT=6, K3=6, SIG_Z=6, NOISE=6, NEW_BRANCH = 6;
  const int G=6, BRAGG_ANGLE_IN = 6, SYMMETRY = 6;
  const int G_ERR=7, N_POLE=7, BBI_CONST=7, OSC_AMPLITUDE=7;
  const int GRADIENT_ERR=7, CRITICAL_ANGLE = 7;
  const int BRAGG_ANGLE_OUT = 7, IX_TO_BRANCH=7;
  const int RHO=8, VOLTAGE=8, DELTA_E = 8;
  const int CHARGE=8, X_GAIN_CALIB=8, IX_TO_ELEMENT=8;
  const int D1_THICKNESS = 9, VOLTAGE_ERR=9, REL_TRACKING_CHARGE = 9;
  const int L_CHORD=9, KS=9, N_SLICE=9, Y_GAIN_CALIB=9, BRAGG_ANGLE=9;
  const int POLARITY=10, CRUNCH_CALIB=10, ALPHA_ANGLE=10, D2_THICKNESS = 10;
  const int E1=10, E_LOSS=10, DKS_DS=10, GAP=10;
  const int GRAD_LOSS_SR_WAKE=11, DS_PATH_LENGTH=11;
  const int E2=11, X_OFFSET_CALIB=11, V1_UNITCELL=11, PSI_ANGLE=11;
  const int Y_OFFSET_CALIB=12, V_UNITCELL=12, V2_UNITCELL=12;
  const int TRAVELING_WAVE = 12;
  const int FINT=12, FINTX=13, HGAP=14, HGAPX=15, H1=16, H2=17;
  const int PHI0=13, TILT_CALIB=13, F0_RE=13, F0_RE1=13;
  const int PHI0_ERR=14, COEF=14, CURRENT=14, L_POLE=14, PARTICLE = 14;
  const int QUAD_TILT=14, DE_ETA_MEAS=14, F0_IM=14, F0_IM1 = 14;
  const int GEOMETRY = 15, BEND_TILT=15, MODE=15;
  const int DPHI0=15, N_SAMPLE=15, FH_RE=15, F0_RE2=15, ORIGIN_ELE_REF_PT=15;
  const int DPHI0_REF = 16, FH_IM=16, F0_IM2=16, X_HALF_LENGTH=16, DX_ORIGIN= 16;
  const int LATTICE_TYPE = 16, X_QUAD=16;
  const int DPHI0_MAX=17, REF_POLARIZATION=17, Y_HALF_LENGTH=17, DY_ORIGIN = 17, Y_QUAD=17;
  const int FRINGE_TYPE = 18, FLOOR_SET = 18, PTC_DIR = 18, DZ_ORIGIN = 18;
  const int KILL_FRINGE = 19, DTHETA_ORIGIN = 19, B_PARAM = 19;
  const int L_HARD_EDGE = 20, DPHI_ORIGIN = 20, REF_CAP_GAMMA = 20;
  const int FIELD_SCALE = 21, DPSI_ORIGIN = 21, DARWIN_WIDTH_SIGMA = 21;
  const int ANGLE=22, N_CELL=22, X_RAY_LINE_LEN=22, DARWIN_WIDTH_PI = 22;
  const int X_PITCH = 23;
  const int Y_PITCH = 24;
  const int X_OFFSET = 25;
  const int Y_OFFSET = 26;
  const int Z_OFFSET = 27;
  const int HKICK = 28, D_SPACING = 28, T_OFFSET = 28;
  const int VKICK = 29, L_X = 29;
  const int BL_HKICK = 30, L_Y = 30;
  const int BL_VKICK = 31, L_Z = 31;
  const int BL_KICK = 32, COUPLER_AT = 32;
  const int B_FIELD = 33, E_FIELD = 33, COUPLER_PHASE = 33;
  const int COUPLER_ANGLE = 34, B_FIELD_ERR = 34;
  const int COUPLER_STRENGTH = 35;
  const int B1_GRADIENT = 35, E1_GRADIENT = 35;
  const int B2_GRADIENT = 36, E2_GRADIENT = 36, H_X_NORM = 36;
  const int B3_GRADIENT = 37, E3_GRADIENT = 37, H_Y_NORM = 37, PTC_FIELD_GEOMETRY = 38;
  const int BS_FIELD = 38, E_TOT_OFFSET = 38, H_Z_NORM = 38;
  const int DELTA_REF_TIME = 39;
  const int P0C_START = 40;
  const int E_TOT_START = 41;
  const int P0C = 42;
  const int E_TOT = 43;
  const int X_PITCH_TOT = 44, NO_END_MARKER = 44;
  const int Y_PITCH_TOT = 45;
  const int X_OFFSET_TOT = 46;
  const int Y_OFFSET_TOT = 47;
  const int Z_OFFSET_TOT = 48;
  const int TILT_TOT = 49, ROLL_TOT = 49;
  const int POLE_RADIUS = 50, REF_TILT_TOT = 50;
  const int N_REF_PASS = 51;
  const int RADIUS = 52;
  const int REF_TIME_START = 53;
  const int THICKNESS = 54, INTEGRATOR_ORDER = 54;
  const int NUM_STEPS = 55;
  const int DS_STEP = 56;
  const int LORD_PAD1 = 57;
  const int LORD_PAD2 = 58, REF_WAVELENGTH = 58;
  const int SCRATCH = 59;
  const int CUSTOM_ATTRIBUTE1 = 61;
  const int CUSTOM_ATTRIBUTE2 = 62;
  const int CUSTOM_ATTRIBUTE3 = 63;
  const int CUSTOM_ATTRIBUTE4 = 64;
  const int CUSTOM_ATTRIBUTE5 = 65, CUSTOM_ATTRIBUTE_MAX = 65;
  const int X1_LIMIT = 66;
  const int X2_LIMIT = 67;
  const int Y1_LIMIT = 68;
  const int Y2_LIMIT = 69;
  const int CHECK_SUM = 70;
  const int LR_WAKE_FILE = 71, ALPHA_B = 71, USE_HARD_EDGE_DRIFTS = 71;
  const int ALIAS =72, ETA_X = 72, PTC_MAX_FRINGE_ORDER = 72;
  const int START_EDGE =73, ETA_Y = 73;
  const int END_EDGE =74, ETAP_X = 74;
  const int ACCORDION_EDGE =75, ETAP_Y = 75;
  const int LATTICE = 76, PHI_A = 76, DIFFRACTION_TYPE = 76;
  const int APERTURE_TYPE = 77, ETA_Z = 77;
  const int MAP_WITH_OFFSETS = 78, CMAT_11 = 78, SURFACE_ATTRIB = 78;
  const int CSR_CALC_ON = 79, CMAT_12 = 79;
  const int S_POSITION = 80, CMAT_21 = 80;
  const int MAT6_CALC_METHOD = 81, CMAT_22 = 81;
  const int TRACKING_METHOD  = 82, S_LONG = 82;
  const int REF_TIME = 83, PTC_INTEGRATION_TYPE = 83;
  const int SPIN_TRACKING_METHOD = 84, ETA_A = 84;
  const int APERTURE = 85, RF_AUTO_SCALE_AMP = 85, ETAP_A = 85;
  const int X_LIMIT = 86, ABSOLUTE_TIME_TRACKING = 86, ETA_B = 86;
  const int Y_LIMIT = 87, RF_AUTO_SCALE_PHASE = 87, ETAP_B = 87;
  const int OFFSET_MOVES_APERTURE = 88;
  const int APERTURE_LIMIT_ON = 89;
  const int PTC_EXACT_MISALIGN = 90;
  const int SR_WAKE_FILE = 90, ALPHA_A = 90;
  const int TERM = 91, USE_PTC_LAYOUT = 91;
  const int X_POSITION = 92, S_SPLINE = 92, PTC_EXACT_MODEL = 92;
  const int SYMPLECTIFY = 93, Y_POSITION = 93, N_SLICE_SPLINE = 93;
  const int Z_POSITION = 94;
  const int IS_ON = 95, THETA_POSITION = 95;
  const int FIELD_CALC = 96, PHI_POSITION = 96;
  const int PSI_POSITION = 97;
  const int APERTURE_AT = 98, BETA_A = 98;
  const int RAN_SEED = 99, BETA_B = 99, ORIGIN_ELE= 99;
  const int TO_LINE = 100;
  const int FIELD_MASTER = 101, HARMON_MASTER = 101, TO_ELEMENT = 101;
  const int DESCRIP = 102;
  const int SCALE_MULTIPOLES = 103;
  const int WALL_ATTRIBUTE = 104;
  const int FIELD = 105;
  const int PHI_B = 106, CRYSTAL_TYPE = 106, MATERIAL_TYPE = 106;
  const int TYPE = 107;
  const int REF_ORIGIN = 108;
  const int ELE_ORIGIN = 109;
  const int SUPERIMPOSE    = 110;
  const int OFFSET         = 111;
  const int REFERENCE      = 112;
  const int ELE_BEGINNING  = 113;
  const int ELE_CENTER     = 114;
  const int ELE_END        = 115;
  const int REF_BEGINNING  = 116;
  const int REF_CENTER     = 117;
  const int REF_END        = 118;
  const int CREATE_JUMBO_SLAVE = 119;
  const int A0  = 120, K0L  = 120;
  const int A20 = 140, K20L = 140;
  const int B0  = 150, T0  = 150;
  const int B20 = 170, T20 = 170;
  const int NUM_ELE_ATTRIB_EXTENDED = T20;
  const int OPEN = 1, CLOSED = 2;
  const int FREE = 1, SUPER_SLAVE = 2, CONTROL_SLAVE = 3;
  const int GROUP_LORD = 4, SUPER_LORD = 5, OVERLAY_LORD = 6;
  const int GIRDER_LORD = 7, MULTIPASS_LORD = 8, MULTIPASS_SLAVE = 9;
  const int NOT_A_LORD = 10, SLICE_SLAVE = 11, CONTROL_LORD = 12;
  const int BMAD_STANDARD = 1, SYMP_LIE_PTC = 2;
  const int RUNGE_KUTTA = 3;
  const int LINEAR = 4, TRACKING = 5, SYMP_MAP = 6;
  const int HARD_EDGE_MODEL = 9, SYMP_LIE_BMAD = 10, STATIC = 11;
  const int BORIS = 12, MAD = 14;
  const int TIME_RUNGE_KUTTA = 15, CUSTOM2 = 16;
  const int N_METHODS = 16;
  const int DRIFT_KICK = 1, MATRIX_KICK = 2, RIPKEN_KICK = 3;
  const int MAP_TYPE = 1, PERIODIC_TYPE = 3, CONST_REF_ENERGY = 4, NONCONST_REF_ENERGY = 5;
  const int GRID = 2, MAP = 3, REFER_TO_LORDS = 4;
  const int BRAGG = 1, LAUE = 2;
  const int BENDS = 201;
  const int WIGGLERS = 202;
  const int ALL = 203;
  const int RADIANS = 1, DEGREES = 2, CYCLES = 3, KHZ = 4;
  const int ROTATIONALLY_SYMMETRIC_RZ = 1;
  const int IS_LOGICAL = 1, IS_INTEGER = 2, IS_REAL = 3, IS_SWITCH = 4, IS_STRING = 5;
  const int RECTANGULAR = 1, ELLIPTICAL = 2, WALL3D = 3;
  const int SIGMA_POLARIZATION = 1, PI_POLARIZATION = 2;
  const int FULL_STRAIGHT = 1, FULL_BEND = 2, NONE = 3, BASIC_BEND = 4;
  const int SECTOR = 1, STRAIGHT = 2, TRUE_RBEND = 3;
  const int N_POLE_MAXX = 20;
  const int NOT_SET = -999;
  const int ANTIMUON   = +3;
  const int PROTON     = +2;
  const int POSITRON   = +1;
  const int PHOTON     =  0;
  const int ELECTRON   = -1;
  const int ANTIPROTON = -2;
  const int MUON       = -3;
  const int S_BLANK   = -1;
  const int S_INFO    = 0;
  const int S_DINFO   = 1;
  const int S_SUCCESS = 2;
  const int S_WARN    = 3;
  const int S_DWARN   = 5;
  const int S_ERROR   = 7;
  const int S_FATAL   = 8;
  const int S_ABORT   = 9;
  const double PI = 3.14159265358979E0;
  const double TWOPI = 2 * PI;
  const double FOURPI = 4 * PI;
  const double SQRT_2 = 1.41421356237310E0;
  const double SQRT_3 = 1.73205080757E0;
  const double E_MASS = 0.510998910E-3;
  const double P_MASS   = 0.938272046E0;
  const double M_ELECTRON = 0.510998910E6;
  const double M_PROTON   = 0.938272046E9;
  const double M_MUON     = 105.65836668E6;
  const double C_LIGHT = 2.99792458E8;
  const double R_E = 2.8179402894E-15;
  const double R_P = R_E * M_ELECTRON / M_PROTON;
  const double E_CHARGE = 1.6021892E-19;
  const double H_PLANCK = 4.13566733E-15;
  const double H_BAR_PLANCK = 6.58211899E-16;
  const double MU_0_VAC = FOURPI * 1E-7;
  const double EPS_0_VAC = 1 / (C_LIGHT*C_LIGHT * MU_0_VAC);
  const double CLASSICAL_RADIUS_FACTOR = 1.439964416E-9;
  const double N_AVOGADRO = 6.02214129E23;
  const double ANOMALOUS_MAG_MOMENT_ELECTRON = 0.001159652193;
  const double ANOMALOUS_MAG_MOMENT_PROTON   = 1.79285;
  const int INT_GARBAGE = -987654;
  const double REAL_GARBAGE = -987654.3;

}

#define BMAD_ENUMS
#endif

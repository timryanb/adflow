   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.4 (r3375) - 10 Feb 2010 15:08
   !
   !  Differentiation of dim in forward (tangent) mode:
   !   variations   of useful results: dim
   !   with respect to varying inputs: x y
   FUNCTION DIM_D(x, xd, y, yd, dim)
   USE PRECISION
   IMPLICIT NONE
   REAL(kind=realtype) :: x, y, z
   REAL(kind=realtype) :: xd, yd
   REAL(kind=realtype) :: dim
   REAL(kind=realtype) :: dim_d
   dim_d = xd - yd
   dim = x - y
   IF (dim .LT. 0.0) THEN
   dim = 0.0
   dim_d = 0.0
   END IF
   END FUNCTION DIM_D

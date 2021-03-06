C PRIMITIVES FOR DEBUGGING THE TANGENT AND ADJOINT CODES GENERATED BY TAPENADE.
C These primitives are called by the code produced by Tapenade when using
C the differentiation command-line options -debugTGT and -debugADJ.

C GLOBAL VARIABLES DEFINED IN debugAD.inc:
C-----------------------------------------
C dbad_mode is 1 when running divided-differences test to validate the tangent mode
C             -1 when running dot-product test to validate the adjoint mode.
C dbad_phase is 1 for the 1st executable that is called for the test
C               2 for the 2nd executable that is called for the test
C           Both tests are run by calling $> exe1 | exe2
C dbad_file is the file that is used to make exe1 communicate towards exe2
C           by default it is std_out (6) in phase 1, and std_in (5) in phase 2.
C           It's not actually parametrable, but one may change this
C           if std_in or std_out are unavailable.
C dbad_ddeps is the epsilon used by divided-differences test ONLY.
C           The test 1st order, not centered.
C           dbad_ddeps is not used in the dot-product test.
C           dbad_ddeps is set by DEBUG_TGT_INIT[1,2], as its 1st argument.
C dbad_epszero is the absolute value under which a derivative is
C           considered to be in fact zero. It is used in both tests
C           to eliminate differences between a zero deriv and an undefined deriv.
C           dbad_epszero is set by DEBUG_TGT_INIT[1,2], as its 2nd argument,
C           and by DEBUG_[F,B]WD_INIT, as its 1st argument.
C dbad_errormax is the percentage of difference above which a "difference"
C           message is issued. In divided-differences test, this is about
C           the comparison of tgt diff wrt divided-differences.
C           In dot-product mode, this is about the comparison between
C           the (sum of the) bwd Jacobian wrt the (sum of the) tgt Jacobian.
C           dbad_errormax is set by DEBUG_TGT_INIT[1,2], as its 3rd argument,
C           and by DEBUG_[F,B]WD_INIT, as its 2nd argument.
C dbad_incr is the increment used to "randomize" the X_d and Y_b used in the
C           dot-product test. X_d and Y_d are filled with values in [1.d0 , 2.d0[,
C           starting with 1.d0 and incremented by steps of dbad_incr.
C           dbad_incr is set by DEBUG_[F,B]WD_INIT, as its 3rd argument.
C dbad_callsz is the max depth of nested calls during execution.
C           It is set by default to 99 in debugAD.inc.
C           It may be changed in debugAD.inc, if needed.
C dbad_callnames is the stack of the procedure names in the current call stack.
C           These names are stored without the _D or _B extension.
C dbad_callcodes is a stack of codes of the current call stack.
C           It is currently not used and may disappear sone day.
C dbad_calltraced is a stack of booleans on the current call stack.
C           "true" means that the current call is being traced.
C           A "false" means not traced, and implies a "false" in all
C           deeper calls. In divided-differences test ONLY, this can be
C           overriden by passing "true" as the 3rd argument of
C           DEBUG_TGT_CALL or DEBUG_TGT_HERE.

      BLOCK DATA DEBUG_AD
      IMPLICIT NONE
      INCLUDE 'debugAD.inc'
      DATA dbad_callindex/0/
      DATA dbad_sum/0.d0/
      DATA dbad_coeff/1.d0/
      DATA dbad_incr/0.137d0/
      END

C DEBUG PRIMITIVES FOR THE TANGENT MODE (DIVIDED-DIFFERENCES METHOD)

      SUBROUTINE DEBUG_TGT_INIT1(epsilon, ezero, errmax)
      IMPLICIT NONE
      REAL*8 epsilon, ezero, errmax
      INCLUDE 'debugAD.inc'
      dbad_mode = 1
      dbad_phase = 1
      dbad_file = 6
      dbad_ddeps = epsilon
      dbad_epszero = ezero
      dbad_errormax = errmax
      end

      SUBROUTINE DEBUG_TGT_INIT2(epsilon, ezero, errmax)
      IMPLICIT NONE
      REAL*8 epsilon, ezero, errmax
      INCLUDE 'debugAD.inc'
      dbad_mode = 1
      dbad_phase = 2
      dbad_file = 5
      dbad_ddeps = epsilon
      dbad_epszero = ezero
      dbad_errormax = errmax
      write (*,'("Starting TGT test, epsilon=",e7.1,
     +     ", zero=",e7.1,", errmax=",f6.1,"%")'),
     +     epsilon,ezero,(100.0*errmax)
      write (*,
     +'("===========================================================")')
      end

      SUBROUTINE DEBUG_TGT_INITREAL4(indep, indepd)
      IMPLICIT NONE
      REAL*4 indep, indepd
      INCLUDE 'debugAD.inc'
      if (dbad_phase.eq.1) then
         indep = indep+dbad_ddeps*indepd
      endif
      end

      SUBROUTINE DEBUG_TGT_INITREAL4ARRAY(indep, indepd, length)
      IMPLICIT NONE
      INTEGER length
      REAL*4 indep(length), indepd(length)
      INCLUDE 'debugAD.inc'
      INTEGER i
      if (dbad_phase.eq.1) then
         do i=1,length
            indep(i) = indep(i)+dbad_ddeps*indepd(i)
         enddo
      endif
      end

      SUBROUTINE DEBUG_TGT_INITREAL8(indep, indepd)
      IMPLICIT NONE
      REAL*8 indep, indepd
      INCLUDE 'debugAD.inc'
      if (dbad_phase.eq.1) then
         indep = indep+dbad_ddeps*indepd
      endif
      end

      SUBROUTINE DEBUG_TGT_INITREAL8ARRAY(indep, indepd, length)
      IMPLICIT NONE
      INTEGER length
      REAL*8 indep(length), indepd(length)
      INCLUDE 'debugAD.inc'
      INTEGER i
      if (dbad_phase.eq.1) then
         do i=1,length
            indep(i) = indep(i)+dbad_ddeps*indepd(i)
         enddo
      endif
      end

      SUBROUTINE DEBUG_TGT_CONCLUDEREAL4(varname, var, vard)
      IMPLICIT NONE
      character varname*(*)
      real*4 var, vard
      INCLUDE 'debugAD.inc'
      REAL*4 ddvar, dd, diff, varwr
      LOGICAL areNaNs
      if (dbad_phase.eq.1) then
         write (dbad_file, '(a)') 'final_result'
         write (dbad_file, *) var
      else
         call DDCHECKVARNAME('final_result')
         call DDPICKTWO4(var, varwr, dbad_file, ddvar, areNaNs)
         if (.not.areNaNs) then
            dd = (ddvar-varwr)/dbad_ddeps
            diff = (abs(vard-dd)*100.0)/ max(abs(vard),abs(dd))
            write (*,'("Final result",a20,": ",e20.8," (ad)",
     +           f9.5,"% DIFF WITH (dd) ",e20.8)')
     +           varname,vard,diff,dd
         else
            write (*, '(a)') 'Final result has NaNs'
         endif
      endif
      write (*,
     +'("===========================================================")')
      END

      SUBROUTINE DEBUG_TGT_CONCLUDEREAL4ARRAY
     +                           (varname, tvar, tvard, length)
      IMPLICIT NONE
      integer length
      real*4 tvar(length)
      real*4 tvard(length)
      character varname*(*)
      REAL*4 var, vard
      INTEGER i
      var = 0.0
      vard = 0.0
      DO i=1,length
         var = var + tvar(i)
         vard = vard + tvard(i)
      ENDDO
      call DEBUG_TGT_CONCLUDEREAL4(varname, var, vard)
      END

      SUBROUTINE DEBUG_TGT_CONCLUDEREAL8(varname, var, vard)
      IMPLICIT NONE
      character varname*(*)
      real*8 var, vard
      INCLUDE 'debugAD.inc'
      REAL*8 ddvar, dd, diff, varwr
      LOGICAL areNaNs
      if (dbad_phase.eq.1) then
         write (dbad_file, '(a)') 'final_result'
         write (dbad_file, *) var
      else
         call DDCHECKVARNAME('final_result')
         call DDPICKTWO8(var, varwr, dbad_file, ddvar, areNaNs)
         if (.not.areNaNs) then
            dd = (ddvar-varwr)/dbad_ddeps
            diff = (abs(vard-dd)*100.0)/ max(abs(vard),abs(dd))
            write (*,'("Final result",a20,": ",e24.16," (ad)",
     +           f9.5,"% DIFF WITH (dd) ",e24.16)')
     +           varname,vard,diff,dd
         else
            write (*, '(a)') 'Final result has NaNs'
         endif
      endif
      write (*,
     +'("===========================================================")')
      END

      SUBROUTINE DEBUG_TGT_CONCLUDEREAL8ARRAY
     +                           (varname, tvar, tvard, length)
      IMPLICIT NONE
      integer length
      real*8 tvar(length)
      real*8 tvard(length)
      character varname*(*)
      REAL*8 var, vard
      INTEGER i
      var = 0.d0
      vard = 0.d0
      DO i=1,length
         var = var + tvar(i)
         vard = vard + tvard(i)
      ENDDO
      call DEBUG_TGT_CONCLUDEREAL8(varname, var, vard)
      END

      SUBROUTINE DEBUG_TGT_CALL(unitname, traced, forcetraced)
      IMPLICIT NONE
      CHARACTER unitname*(*)
      LOGICAL traced, forcetraced
      INCLUDE 'debugAD.inc'
      dbad_callindex = dbad_callindex+1
      write (dbad_callnames(dbad_callindex),'(a40)') unitname
      dbad_calltraced(dbad_callindex) =
     +     ((dbad_callindex.eq.1.OR.
     +       dbad_calltraced(dbad_callindex-1))
     +     .AND.traced) .OR. forcetraced
      END

      SUBROUTINE DEBUG_TGT_EXIT()
      IMPLICIT NONE
      INCLUDE 'debugAD.inc'
      dbad_callindex = dbad_callindex-1
      END

      LOGICAL FUNCTION DEBUG_TGT_HERE(placename, forcetraced)
      IMPLICIT NONE
      CHARACTER placename*(*)
      LOGICAL forcetraced
      INCLUDE 'debugAD.inc'
      DEBUG_TGT_HERE =
     +     (dbad_callindex.eq.0.OR.dbad_calltraced(dbad_callindex))
     +     .OR.forcetraced
      RETURN
      END

      SUBROUTINE DEBUG_TGT_REAL4(varname, var, vard)
      IMPLICIT NONE
      character varname*(*)
      REAL*4 var, vard
      INCLUDE 'debugAD.inc'
      REAL*4 ddvar, dd, diff, varwr
      LOGICAL areNaNs
      character*12 diffstr
      character*50 ddvarname
      if (dbad_phase.eq.1) then
         WRITE(dbad_file, '(a)') varname
         WRITE(dbad_file, *) var
      else if (dbad_phase.eq.2) then
         call DDCHECKVARNAME(varname)
         call DDPICKTWO4(var, varwr, dbad_file, ddvar, areNaNs)
         if (.not.areNaNs) then
            dd = (ddvar-varwr)/dbad_ddeps
            if ((abs(vard).gt.dbad_epszero)
     +           .or.(abs(dd).gt.dbad_epszero)) then
               diff = (abs(vard-dd)*100.0)/max(abs(vard),abs(dd))
               if (diff.gt.dbad_errormax) then
                  diffstr = 'DIFFERENCE!!'
               else
                  diffstr = '            '
               endif
               write (*,'("   ", a,":",e10.4,
     +              " (dd:",e10.4,")   ",a14)')
     +              varname, vard, dd, diffstr
            endif
         endif
      endif
      END

      SUBROUTINE DEBUG_TGT_REAL4ARRAY (varname, var, vard, length)
      IMPLICIT NONE
      integer length
      real*4 var(length)
      real*4 vard(length)
      character varname*(*)
      INCLUDE 'debugAD.inc'
      real*4 ddvar, dd, diff, varwr
      real*4 valbuf(10),ddbuf(10)
      character*50 ddvarname
      integer indexbuf1(10)
      character*14 diffbuf(10)
      integer i1,j
      integer ibuf
      logical notprintedheader
      LOGICAL areNaNs
      if (dbad_phase.eq.1) then
         WRITE(dbad_file, '(a)') varname
         do i1=1,length
            WRITE(dbad_file, *) var(i1)
         enddo
      else if (dbad_phase.eq.2) then
         call DDCHECKVARNAME(varname)
         notprintedheader=.true.
         ibuf = 1
         do i1=1,length
            call DDPICKTWO4(var(i1),varwr,dbad_file,ddvar,areNaNs)
            if (.not.areNaNs) then
               dd = (ddvar-varwr)/dbad_ddeps
               if ((abs(vard(i1)).gt.dbad_epszero)
     +              .or.(abs(dd).gt.dbad_epszero)) then
                  valbuf(ibuf) = vard(i1)
                  ddbuf(ibuf) = dd
                  indexbuf1(ibuf) = i1
                  diff = (abs(vard(i1)-dd)*100.0)
     +                    /max(abs(vard(i1)),abs(dd))
                  if (diff.gt.dbad_errormax) then
                     diffbuf(ibuf) = '  DIFFERENCE!!'
                     ibuf = ibuf+1
                  else
!                     diffbuf(ibuf) = '              '
!                     ibuf = ibuf+1
                  endif
               endif
            endif
            if(ibuf.gt.10.or.(i1.eq.length.and.ibuf.gt.1)) then
               if (notprintedheader) then
                  write(*,'("   ", a, ":")') varname
                  notprintedheader=.false.
               endif
               write (*, '("          ", 10(i4,"->",e10.4))')
     +              (indexbuf1(j),valbuf(j), j=1,ibuf-1)
               write (*, '("      (dd:)", 10("    (",e10.4,")"))')
     +              (ddbuf(j), j=1,ibuf-1)
               write (*, '("          ", 10(a16))')
     +              (diffbuf(j), j=1,ibuf-1)
               ibuf = 1
            endif
         end do
      endif
      END

      SUBROUTINE DDPICKTWO4(var, varwr, dbad_file, ddvar, areNaNs)
      IMPLICIT NONE
      REAL*4 var,varwr,ddvar
      LOGICAL areNaNs
      INTEGER dbad_file,stat1,stat2
      OPEN(38, FILE='ddwrfile')
      WRITE(38, *) var
      REWIND(38)
      READ(38, *,IOSTAT=stat1) varwr
      CLOSE(38)
      READ(dbad_file, *,IOSTAT=stat2) ddvar
      areNaNs = stat1.eq.225.and.stat2.eq.225
      END

      SUBROUTINE DEBUG_TGT_REAL8(varname, var, vard)
      IMPLICIT NONE
      CHARACTER varname*(*)
      REAL*8 var, vard
      INCLUDE 'debugAD.inc'
      REAL*8 ddvar, dd, diff, varwr
      character*12 diffstr
      character*50 ddvarname
      LOGICAL areNaNs
      if (dbad_phase.eq.1) then
         WRITE(dbad_file, '(a)') varname
         WRITE(dbad_file, *) var
      else if (dbad_phase.eq.2) then
         call DDCHECKVARNAME(varname)
         call DDPICKTWO8(var, varwr, dbad_file, ddvar, areNaNs)
         if (.not.areNaNs) then
            dd = (ddvar-varwr)/dbad_ddeps
            if ((abs(vard).gt.dbad_epszero)
     +           .or.(abs(dd).gt.dbad_epszero)) then
               diff = (abs(vard-dd)*100.0)/ max(abs(vard),abs(dd))
               if (diff.gt.dbad_errormax) then
                  diffstr = 'DIFFERENCE!!'
                  write (*,'(a20,":  ",e24.16," (ad)",
     +                 f5.1,"% DIFF WITH (dd) ",e24.16)')
     +                 varname, vard, diff, dd
               else
                  diffstr = '            '
               endif
!               write (*,*),ddvar,varwr,dd,'=?=',vard,' %',diff,varname
!               write (*, *) varname, vard, 'dd:', dd, diffstr
            endif
         endif
      endif
      END

      SUBROUTINE DEBUG_TGT_REAL8ARRAY(varname, var, vard, length)
      IMPLICIT NONE
      integer length
      real*8 var(length)
      real*8 vard(length)
      character varname*(*)
      INCLUDE 'debugAD.inc'
      LOGICAL areNaNs
      real*8 ddvar, dd, diff, varwr
      real*8 valbuf(10),ddbuf(10)
      character*50 ddvarname
      integer indexbuf1(10)
      character*14 diffbuf(10)
      integer i1,j
      integer ibuf
      logical notprintedheader
      if (dbad_phase.eq.1) then
         WRITE(dbad_file, '(a)') varname
         do i1=1,length
            WRITE(dbad_file, *) var(i1)
         enddo
      else if (dbad_phase.eq.2) then
         call DDCHECKVARNAME(varname)
         notprintedheader=.true.
         ibuf = 1
         do i1=1,length
            call DDPICKTWO8(var(i1),varwr,dbad_file,ddvar,areNaNs)
            if (.not.areNaNs) then
               dd = (ddvar-varwr)/dbad_ddeps
               if ((abs(vard(i1)).gt.dbad_epszero)
     +              .or.(abs(dd).gt.dbad_epszero)) then
                  valbuf(ibuf) = vard(i1)
                  ddbuf(ibuf) = dd
                  indexbuf1(ibuf) = i1
                  diff = (abs(vard(i1)-dd)*100.0)
     +                 /max(abs(vard(i1)),abs(dd))
                  if (diff.gt.dbad_errormax) then
 99                  format(E14.8)
                     write(diffbuf(ibuf),99) diff
                     !diffbuf(ibuf) = '  DIFFERENCE!!'
                     ibuf = ibuf+1
                  else
!                     diffbuf(ibuf) = '              '
!                     ibuf = ibuf+1
                  endif
               endif
            endif
            if(ibuf.gt.10.or.(i1.eq.length.and.ibuf.gt.1)) then
               if (notprintedheader) then
                  write(*,'("   ", a, ":")') varname
                  notprintedheader=.false.
               endif
               write (*, '("          ", 10(i6,"->",e10.4))')
     +              (indexbuf1(j),valbuf(j), j=1,ibuf-1)
               write (*, '("      (dd:)", 10("      (",e10.4,")"))')
     +              (ddbuf(j), j=1,ibuf-1)
               write (*, '("     (err:)", 10(a18))')
     +              (diffbuf(j), j=1,ibuf-1)
               ibuf = 1
            endif
         end do
      endif
      END

      SUBROUTINE DDPICKTWO8(var, varwr, dbad_file, ddvar, areNaNs)
      IMPLICIT NONE
      REAL*8 var,varwr,ddvar
      LOGICAL areNaNs
      INTEGER dbad_file,stat1,stat2
      OPEN(38, FILE='ddwrfile')
      WRITE(38, *) var
      REWIND(38)
      READ(38, *,IOSTAT=stat1) varwr
      CLOSE(38)
      READ(dbad_file, *,IOSTAT=stat2) ddvar
      areNaNs = stat1.eq.225.and.stat2.eq.225
      END

      SUBROUTINE DDCHECKVARNAME(varname)
      IMPLICIT NONE
      character varname*(*)
      INCLUDE 'debugAD.inc'
      character*50 ddvarname
      integer linesskip
      linesskip = 0
 100  CONTINUE
      if (linesskip.GT.200) THEN
         write(*,*)
     +    'ERROR: Too many lines skipped. Bad DD program control ?'
         write(*,*) 'Was looking for variable:',varname
         STOP
      ENDIF
      READ(dbad_file, '(a)') ddvarname
      if (ddvarname.ne.varname) then
!         write(*,*) 'ERROR: mismatch in DD program control !!!',
!     +        ' read ', ddvarname, ' expecting ', varname
         linesskip = linesskip+1
         GOTO 100
      endif
      END

      SUBROUTINE DEBUG_TGT_DISPLAY(placename)
      IMPLICIT NONE
      CHARACTER placename*(*)
      INCLUDE 'debugAD.inc'
      if (dbad_phase.eq.2) then
         CALL DEBUG_DISPLAY_LOCATION(placename)
      endif
      END

C DEBUG PRIMITIVES FOR THE ADJOINT MODE, BACKWARD SWEEP (DOT-PRODUCT METHOD)

      SUBROUTINE DEBUG_BWD_INIT(ezero, errmax, incr)
      IMPLICIT NONE
      REAL*8 ezero, errmax, incr
      INCLUDE 'debugAD.inc'
      dbad_mode = -1
      dbad_phase = 1
      dbad_file = 6
      dbad_epszero = ezero
      dbad_errormax = errmax
      dbad_incr = incr
      write(dbad_file,'(i3,a40)') 3, 'StartOfPhase1'
      END

      SUBROUTINE DEBUG_BWD_CONCLUDE()
      IMPLICIT NONE
      INCLUDE 'debugAD.inc'
      REAL*8 sumd
      INTEGER*4 smallsize, nbblocks, SMALLSTACKSIZE
      INTEGER*4 nbreals, i
      write(dbad_file,'(i3,a40)') -3, 'EndOfPhase1'
      END

      SUBROUTINE DEBUG_BWD_CALL(unitname, traced)
      IMPLICIT NONE
      CHARACTER unitname*(*)
      LOGICAL traced
      INCLUDE 'debugAD.inc'
      dbad_callindex = dbad_callindex+1
      write (dbad_callnames(dbad_callindex),'(a40)') unitname
      dbad_calltraced(dbad_callindex) =
     +     (dbad_callindex.eq.1.OR.
     +       dbad_calltraced(dbad_callindex-1))
     +     .AND.traced
      end

      SUBROUTINE DEBUG_BWD_EXIT()
      IMPLICIT NONE
      INCLUDE 'debugAD.inc'
      IF (dbad_callindex.eq.1 .OR.
     +     dbad_calltraced(dbad_callindex-1)) THEN
         IF (dbad_calltraced(dbad_callindex)) THEN
            write(dbad_file,'(i3,a40)')
     +           2, dbad_callnames(dbad_callindex)
         ELSE
            write(dbad_file,'(i3,a40)')
     +           -2, dbad_callnames(dbad_callindex)
         ENDIF
      ENDIF
      dbad_callindex = dbad_callindex-1
      END

      LOGICAL FUNCTION DEBUG_BWD_HERE(placename)
      IMPLICIT NONE
      CHARACTER placename*(*)
      INCLUDE 'debugAD.inc'
      DEBUG_BWD_HERE =
     +     (dbad_callindex.eq.0.OR.dbad_calltraced(dbad_callindex))
      RETURN
      END

C DEBUG PRIMITIVES FOR THE ADJOINT MODE, FORWARD SWEEP (DOT-PRODUCT METHOD)

      SUBROUTINE DEBUG_FWD_INIT(ezero, errmax, incr)
      IMPLICIT NONE
      REAL*8 ezero, errmax, incr
      INCLUDE 'debugAD.inc'
      INTEGER label
      CHARACTER*40 startstring
      CHARACTER*40 placestring
      REAL*8 bigsum
      dbad_mode = -1
      dbad_phase = 2
      dbad_file = 5
      dbad_epszero = ezero
      dbad_errormax = errmax
      dbad_incr = incr
      dbad_nberrors = 0
      write (*,'("Starting ADJ test, zero=",e7.1,
     +     ", errmax=",f4.1,"%, random_incr=",e8.2)'),
     +     ezero,(100.0*errmax),incr
      write (*,
     +'("===========================================================")')
C labels:  3 -> StartOfPhase1
C         -1 -> a debug point, skipped
C          0 -> a debug point, traced but no associated value.
C          1 -> a debug point, traced, with an associated value.
C         -2 -> a call, skipped
C          2 -> a call, traced
C         -3 -> EndOfPhase1
 100  READ(dbad_file,'(i3,a40)',ERR=200,END=500) label,startstring
      if (label.eq.3.AND.
     +     startstring.EQ.'                           StartOfPhase1')
     +     GOTO 300
 200  GOTO 100
 300  CALL PUSHINTEGER4(3)
 400  READ(dbad_file,'(i3,a40)',ERR=500,END=500) label,placestring
      IF (label.eq.-3) GOTO 500
      IF (label.eq.1) THEN
         READ(dbad_file,*) bigsum
         CALL PUSHREAL8(bigsum)
      ENDIF
      CALL PUSHCHARACTERARRAY(placestring, 40)
      CALL PUSHINTEGER4(label)
      GOTO 400
 500  CONTINUE
C FOR DEBUG OF DEBUG ONLY:
c      CALL LOOKINTEGER4(label)
c      IF (label.eq.3) GOTO 600
c      call LOOKCHARACTERARRAY(placestring, 40)
c      if (label.eq.-2) then
c         write (*,*) 'untraced  call ',placestring
c      else if (label.eq.2) then
c         write (*,*) 'TRACED    call ',placestring
c      else if (label.eq.-1) then
c         write (*,*) 'untraced place ',placestring
c      else if (label.eq.1) then
c         write (*,*) 'TRACED   place ',placestring
c      else if (label.eq.0) then
c         call LOOKREAL8(bigsum)
c         write (*,*) 'TRACED   place ',placestring, bigsum
c      endif
c      GOTO 500
C end FOR DEBUG OF DEBUG ONLY.
 600  CONTINUE
      END

      SUBROUTINE DEBUG_FWD_CONCLUDE()
      IMPLICIT NONE
      INCLUDE 'debugAD.inc'
      write (*,'("End of ADJ test.",i2,
     +     " error(s) found. WARNING: testing alters derivatives!")')
     +     dbad_nberrors
      write (*,
     +'("===========================================================")')
      END

      SUBROUTINE DEBUG_FWD_CALL(unitname)
      IMPLICIT NONE
      CHARACTER unitname*(*)
      INCLUDE 'debugAD.inc'
      INTEGER label
      CHARACTER*40 refcallstring, herecallstring
      label = 999
      IF (dbad_callindex.eq.0.OR.dbad_calltraced(dbad_callindex)) THEN
         call POPINTEGER4(label)
         IF (label.ne.2 .AND. label.ne.-2) THEN
            write(*,*) 'Control mismatch: FWD call ',
     +           unitname,'; BWD ',label
            STOP
         ENDIF
         call POPCHARACTERARRAY(refcallstring, 40)
         write (herecallstring,'(a40)') unitname
         IF (refcallstring.NE.herecallstring) THEN
            write(*,*) 'Control mismatch: FWD call ',
     +           herecallstring,'; BWD call ',refcallstring
            STOP
         ENDIF
      ENDIF
      dbad_callindex = dbad_callindex+1
      write (dbad_callnames(dbad_callindex),'(a40)') unitname
      dbad_calltraced(dbad_callindex) = (label.eq.2)
      END

      SUBROUTINE DEBUG_FWD_EXIT()
      IMPLICIT NONE
      INCLUDE 'debugAD.inc'
      dbad_callindex = dbad_callindex-1
      END

      LOGICAL FUNCTION DEBUG_FWD_HERE(placename)
      IMPLICIT NONE
      CHARACTER placename*(*)
      INCLUDE 'debugAD.inc'
      INTEGER label
      CHARACTER*40 refplacestring, hereplacestring
      label = 999
      IF (dbad_callindex.eq.0.OR.dbad_calltraced(dbad_callindex)) THEN
         call POPINTEGER4(label)
         IF (label.ne.1 .AND. label.ne.0 .AND. label.ne.-1) THEN
            write(*,*) 'Control mismatch: FWD place ',
     +           placename,'; BWD ',label
            STOP
         ENDIF
         call POPCHARACTERARRAY(refplacestring, 40)
         write (hereplacestring,'(a40)') placename
         IF (refplacestring.NE.hereplacestring) THEN
            write(*,*) 'Control mismatch: FWD place ',
     +           hereplacestring,'; BWD place ',refplacestring
            STOP
         ENDIF
         DEBUG_FWD_HERE = (label.NE.-1)
         IF (label.eq.1) THEN
            call POPREAL8(dbad_nextrefsum)
         ENDIF
      ELSE
         DEBUG_FWD_HERE = .FALSE.
      ENDIF
      RETURN
      END

C DEBUG PRIMITIVES FOR THE ADJOINT MODE, BOTH SWEEPS (DOT-PRODUCT METHOD)

      SUBROUTINE DEBUG_ADJ_SKIP(placename)
      IMPLICIT NONE
      CHARACTER placename*(*)
      INCLUDE 'debugAD.inc'
      IF (dbad_phase.eq.1) THEN
         IF (dbad_callindex.eq.0 .OR.
     +        dbad_calltraced(dbad_callindex)) THEN
            write(dbad_file,'(i3,a40)') -1, placename
         ENDIF
      ENDIF
      END

      SUBROUTINE DEBUG_ADJ_rwREAL4(vard)
      IMPLICIT NONE
      REAL*4 vard
      INCLUDE 'debugAD.inc'
      CALL DEBUG_ADJ_INCRCOEFF()
      dbad_sum = dbad_sum + dbad_coeff*vard
      vard = dbad_coeff
      END

      SUBROUTINE DEBUG_ADJ_rREAL4(vard)
      IMPLICIT NONE
      REAL*4 vard
      INCLUDE 'debugAD.inc'
      CALL DEBUG_ADJ_INCRCOEFF()
      dbad_sum = dbad_sum + dbad_coeff*vard
      END

      SUBROUTINE DEBUG_ADJ_wREAL4(vard)
      IMPLICIT NONE
      REAL*4 vard
      INCLUDE 'debugAD.inc'
      CALL DEBUG_ADJ_INCRCOEFF()
      vard = dbad_coeff
      END

      SUBROUTINE DEBUG_ADJ_rwREAL4ARRAY(vard, length)
      IMPLICIT NONE
      INTEGER length
      REAL*4 vard(length)
      INTEGER i
      DO i=1,length
         CALL DEBUG_ADJ_rwREAL4(vard(i))
      ENDDO
      END

      SUBROUTINE DEBUG_ADJ_rREAL4ARRAY(vard, length)
      IMPLICIT NONE
      INTEGER length
      REAL*4 vard(length)
      INTEGER i
      DO i=1,length
         CALL DEBUG_ADJ_rREAL4(vard(i))
      ENDDO
      END

      SUBROUTINE DEBUG_ADJ_wREAL4ARRAY(vard, length)
      IMPLICIT NONE
      INTEGER length
      REAL*4 vard(length)
      INTEGER i
      DO i=1,length
         CALL DEBUG_ADJ_wREAL4(vard(i))
      ENDDO
      END

      SUBROUTINE DEBUG_ADJ_rwREAL8(vard)
      IMPLICIT NONE
      REAL*8 vard
      INCLUDE 'debugAD.inc'
      CALL DEBUG_ADJ_INCRCOEFF()
      dbad_sum = dbad_sum + dbad_coeff*vard
      vard = dbad_coeff
      END

      SUBROUTINE DEBUG_ADJ_rREAL8(vard)
      IMPLICIT NONE
      REAL*8 vard
      INCLUDE 'debugAD.inc'
      CALL DEBUG_ADJ_INCRCOEFF()
      dbad_sum = dbad_sum + dbad_coeff*vard
      END

      SUBROUTINE DEBUG_ADJ_wREAL8(vard)
      IMPLICIT NONE
      REAL*8 vard
      INCLUDE 'debugAD.inc'
      CALL DEBUG_ADJ_INCRCOEFF()
      vard = dbad_coeff
      END

      SUBROUTINE DEBUG_ADJ_rwREAL8ARRAY(vard, length)
      IMPLICIT NONE
      INTEGER length
      REAL*8 vard(length)
      INTEGER i
      DO i=1,length
         CALL DEBUG_ADJ_rwREAL8(vard(i))
      ENDDO
      END

      SUBROUTINE DEBUG_ADJ_rREAL8ARRAY(vard, length)
      IMPLICIT NONE
      INTEGER length
      REAL*8 vard(length)
      INTEGER i
      DO i=1,length
         CALL DEBUG_ADJ_rREAL8(vard(i))
      ENDDO
      END

      SUBROUTINE DEBUG_ADJ_wREAL8ARRAY(vard, length)
      IMPLICIT NONE
      INTEGER length
      REAL*8 vard(length)
      INTEGER i
      DO i=1,length
         CALL DEBUG_ADJ_wREAL8(vard(i))
      ENDDO
      END

      SUBROUTINE DEBUG_ADJ_rwDISPLAY(placename, deltaindent)
      IMPLICIT NONE
      CHARACTER placename*(*)
      INTEGER deltaindent
      INCLUDE 'debugAD.inc'
      CALL DEBUG_ADJ_rDISPLAY(placename, deltaindent)
      IF (dbad_phase.eq.2) THEN
         dbad_refsum = dbad_nextrefsum
      ENDIF
      END

      SUBROUTINE DEBUG_ADJ_INCRCOEFF()
      IMPLICIT NONE
      INCLUDE 'debugAD.inc'
      dbad_coeff = dbad_coeff + dbad_incr
      IF (dbad_coeff.ge.2.d0) dbad_coeff = dbad_coeff - 1.d0
      END

      SUBROUTINE DEBUG_ADJ_rDISPLAY(placename, deltaindent)
      IMPLICIT NONE
      CHARACTER placename*(*)
      INTEGER deltaindent
      INCLUDE 'debugAD.inc'
      REAL diffpercent
      IF (dbad_phase.eq.1) THEN
         write(dbad_file,'(i3,a40)') 1, placename
         write(dbad_file,*) dbad_sum
      ELSE
         if (abs(dbad_refsum).le.dbad_epszero
     +        .and.abs(dbad_sum).le.dbad_epszero) then
            diffpercent = 0.0
         else
            diffpercent = abs(dbad_refsum-dbad_sum)*100.0
     +           /max(abs(dbad_refsum),abs(dbad_sum))
         endif
         if (diffpercent.le.dbad_errormax) then
c            write (*,'("                                     ok (",
c     +           f4.1,"% )  fwd:",e23.16,"  bwd:",e23.16)')
c     +           diffpercent,dbad_sum,dbad_refsum
         else
            dbad_nberrors = dbad_nberrors+1
            write (*,'("                             ", f5.1,
     +           "% DIFFERENCE!!  fwd:",e23.16,"  bwd:",e23.16)')
     +           diffpercent,dbad_sum,dbad_refsum
         endif
         IF (deltaindent.eq.0) THEN
            CALL DEBUG_DISPLAY_LOCATION(placename)
         ENDIF
      ENDIF
      dbad_sum = 0.d0
      dbad_coeff = 1.d0
      END

      SUBROUTINE DEBUG_ADJ_wDISPLAY(placename, deltaindent)
      IMPLICIT NONE
      CHARACTER placename*(*)
      INTEGER deltaindent
      INCLUDE 'debugAD.inc'
      IF (dbad_phase.eq.1) THEN
         write(dbad_file,'(i3,a40)') 0, placename
      ELSE
         IF (deltaindent.eq.0) THEN
            CALL DEBUG_DISPLAY_LOCATION(placename)
         ENDIF
         dbad_refsum = dbad_nextrefsum
      ENDIF
      dbad_sum = 0.d0
      dbad_coeff = 1.d0
      END

      SUBROUTINE DEBUG_DISPLAY_LOCATION(placename)
      IMPLICIT NONE
      CHARACTER placename*(*)
      INCLUDE 'debugAD.inc'
      CHARACTER whites*(50),enclosproc*(40)
      whites = '                                                  '
      if (dbad_callindex.EQ.0) then
         enclosproc = 'Top level'
      else
         enclosproc = dbad_callnames(dbad_callindex)
      endif
      write(*,*) whites(:2*(dbad_callindex-1)),
     +     ' AT:',placename,' OF ',enclosproc
      END

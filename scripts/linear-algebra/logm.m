########################################################################
##
## Copyright (C) 2008-2023 The Octave Project Developers
##
## See the file COPYRIGHT.md in the top-level directory of this
## distribution or <https://octave.org/copyright/>.
##
## This file is part of Octave.
##
## Octave is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## Octave is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <https://www.gnu.org/licenses/>.
##
########################################################################

## -*- texinfo -*-
## @deftypefn  {} {@var{s} =} logm (@var{A})
## @deftypefnx {} {@var{s} =} logm (@var{A}, @var{opt_iters})
## @deftypefnx {} {[@var{s}, @var{iters}] =} logm (@dots{})
## Compute the matrix logarithm of the square matrix @var{A}.
##
## The implementation utilizes a Pad@'e approximant and the identity
##
## @example
## logm (@var{A}) = 2^k * logm (@var{A}^(1 / 2^k))
## @end example
##
## The optional input @var{opt_iters} is the maximum number of square roots
## to compute and defaults to 100.
##
## The optional output @var{iters} is the number of square roots actually
## computed.
## @seealso{expm, sqrtm}
## @end deftypefn

## Reference: N. J. Higham, Functions of Matrices: Theory and Computation
##            (SIAM, 2008.)
##

## Author: N. J. Higham
## Author: Richard T. Guy <guyrt7@wfu.edu>

function [s, iters] = logm (A, opt_iters = 100)

  if (nargin == 0)
    print_usage ();
  endif

  if (! issquare (A))
    error ("logm: A must be a square matrix");
  endif

  if (isscalar (A))
    s = log (A);
    return;
  elseif (isdiag (A))
    s = diag (log (diag (A)));
    return;
  endif

  [u, s] = schur (A);

  if (isreal (A))
    [u, s] = rsf2csf (u, s);
  endif

  eigv = diag (s);
  n = rows (A);
  tol = n * eps (max (abs (eigv)));
  real_neg_eigv = (real (eigv) < -tol) & (imag (eigv) <= tol);
  if (any (real_neg_eigv))
    warning ("Octave:logm:non-principal",
             "logm: principal matrix logarithm is not defined for matrices with negative eigenvalues; computing non-principal logarithm");
  endif

  real_eig = ! any (real_neg_eigv);

  if (max (abs (triu (s,1))(:)) < tol)
    ## Will run for Hermitian matrices as Schur decomposition is diagonal.
    ## This way is faster and more accurate but only works on a diagonal matrix.
    logeigv = log (eigv);
    logeigv(isinf (logeigv)) = -log (realmax ());
    s = u * diag (logeigv) * u';
    iters = 0;
  else
    k = 0;
    ## Algorithm 11.9 in "Function of matrices", by N. Higham
    theta = [0, 0, 1.61e-2, 5.38e-2, 1.13e-1, 1.86e-1, 2.6429608311114350e-1];
    p = 0;
    m = 7;
    while (k < opt_iters)
      tau = norm (s - eye (n), 1);
      if (tau <= theta (7))
        p += 1;
        j(1) = find (tau <= theta, 1);
        j(2) = find (tau / 2 <= theta, 1);
        if (j(1) - j(2) <= 1 || p == 2)
          m = j(1);
          break;
        endif
      endif
      k += 1;
      s = sqrtm (s);
    endwhile

    if (k >= opt_iters)
      warning ("logm: maximum number of square roots exceeded; results may still be accurate");
    endif

    s -= eye (n);

    if (m > 1)
      s = logm_pade_pf (s, m);
    endif

    s = 2^k * u * s * u';

    if (nargout == 2)
      iters = k;
    endif
  endif
  ## Remove small complex values (O(eps)) which may have entered calculation
  if (real_eig && isreal (A))
    s = real (s);
  endif

endfunction

################## ANCILLARY FUNCTIONS ################################
######  Taken from the mfttoolbox (GPL 3) by D. Higham.
######  Reference:
######      D. Higham, Functions of Matrices: Theory and Computation
######      (SIAM, 2008.).
#######################################################################

## LOGM_PADE_PF   Evaluate Pade approximant to matrix log by partial fractions.
##   Y = LOGM_PADE_PF(A,M) evaluates the [M/M] Pade approximation to
##   LOG(EYE(SIZE(A))+A) using a partial fraction expansion.

function s = logm_pade_pf (A, m)

  [nodes, wts] = gauss_legendre (m);
  ## Convert from [-1,1] to [0,1].
  nodes = (nodes+1)/2;
  wts /= 2;

  n = length (A);
  s = zeros (n);
  for j = 1:m
    s += wts(j)*(A/(eye (n) + nodes(j)*A));
  endfor

endfunction

######################################################################
## GAUSS_LEGENDRE  Nodes and weights for Gauss-Legendre quadrature.
##   [X,W] = GAUSS_LEGENDRE(N) computes the nodes X and weights W
##   for N-point Gauss-Legendre quadrature.

## Reference:
## G. H. Golub and J. H. Welsch, Calculation of Gauss quadrature
## rules, Math. Comp., 23(106):221-230, 1969.

function [x, w] = gauss_legendre (n)

  i = 1:n-1;
  v = i./sqrt ((2*i).^2-1);
  [V, D] = eig (diag (v, -1) + diag (v, 1));
  x = diag (D);
  w = 2*(V(1,:)'.^2);

endfunction


%!assert (norm (logm ([1 -1;0 1]) - [0 -1; 0 0]) < 1e-5)
%!test
%! warning ("off", "Octave:logm:non-principal", "local");
%! assert (norm (expm (logm ([-1 2 ; 4 -1])) - [-1 2 ; 4 -1]) < 1e-5);
%!assert (logm ([1 -1 -1;0 1 -1; 0 0 1]), [0 -1 -1.5; 0 0 -1; 0 0 0], 1e-5)
%!assert (logm (10), log (10))
%!assert (full (logm (eye (3))), logm (full (eye (3))))
%!assert (full (logm (10*eye (3))), logm (full (10*eye (3))), 8*eps)
%!assert (logm (expm ([0 1i; -1i 0])), [0 1i; -1i 0], 10 * eps)
%!test <*60738>
%! A = [0.2510, 1.2808, -1.2252; ...
%!      0.2015, 1.0766, 0.5630; ...
%!      -1.9769, -1.0922, -0.5831];
%! if (ismac ())
%!   ## The math libraries on macOS seem to require larger tolerances
%!   tol = 60*eps;
%! else
%!   tol = 40*eps;
%! endif
%! warning ("off", "Octave:logm:non-principal", "local");
%! assert (expm (logm (A)), A, tol);
%!assert (expm (logm (eye (3))), eye (3))
%!assert (expm (logm (zeros (3))), zeros (3))

## Test input validation
%!error <Invalid call> logm ()
%!error <logm: A must be a square matrix> logm ([1 0;0 1; 2 2])

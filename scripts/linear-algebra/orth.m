## Copyright (C) 1994, 1995, 1996, 1997, 1998, 1999, 2000, 2005, 2006,
##               2007 John W. Eaton
##
## This file is part of Octave.
##
## Octave is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or (at
## your option) any later version.
##
## Octave is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {} orth (@var{a}, @var{tol})
## Return an orthonormal basis of the range space of @var{a}.
##
## The dimension of the range space is taken as the number of singular
## values of @var{a} greater than @var{tol}.  If the argument @var{tol} is
## missing, it is computed as
##
## @example
## max (size (@var{a})) * max (svd (@var{a})) * eps
## @end example
## @end deftypefn

## Author: KH <Kurt.Hornik@wu-wien.ac.at>
## Created: 24 December 1993.
## Adapted-By: jwe

function retval = orth (A, tol)

  if (nargin == 1 || nargin == 2)

    [U, S, V] = svd (A);

    [rows, cols] = size (A);

    [S_nr, S_nc] = size (S);

    if (S_nr == 1 || S_nc == 1)
      s = S(1);
    else
      s = diag (S);
    endif

    if (nargin == 1)
      if (isa (A, "single"))
	tol = max (size (A)) * s (1) * eps ("single");
      else
	tol = max (size (A)) * s (1) * eps;
      endif
    endif

    rank = sum (s > tol);

    if (rank > 0)
      retval = -U (:, 1:rank);
    else
      retval = zeros (rows, 0);
    endif

  else

    print_usage ();

  endif

endfunction

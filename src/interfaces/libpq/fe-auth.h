/*-------------------------------------------------------------------------
 *
 * fe-auth.h
 *
 *	  Definitions for network authentication routines
 *
 * Portions Copyright (c) 1996-2010, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * $PostgreSQL: pgsql/src/interfaces/libpq/fe-auth.h,v 1.31 2010/01/02 16:58:11 momjian Exp $
 *
 *-------------------------------------------------------------------------
 */
#ifndef FE_AUTH_H
#define FE_AUTH_H

#include "libpq-fe.h"
#include "libpq-int.h"


extern int	pg_fe_sendauth(AuthRequest areq, PGconn *conn);
extern char *pg_fe_getauthname(PQExpBuffer errorMessage);

#endif   /* FE_AUTH_H */

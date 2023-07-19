/*-------------------------------------------------------------------------
 *
 * nodeWindowAgg.h
 *	  prototypes for nodeWindowAgg.c
 *
 *
 * Portions Copyright (c) 1996-2014, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/executor/nodeWindowAgg.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef NODEWINDOWAGG_H
#define NODEWINDOWAGG_H

#include "nodes/execnodes.h"

extern WindowAggState *ExecInitWindowAgg(WindowAgg *node, EState *estate, int eflags);
extern TupleTableSlot *ExecWindowAgg(WindowAggState *node);
extern void ExecEndWindowAgg(WindowAggState *node);
extern void ExecReScanWindowAgg(WindowAggState *node);

extern void ExecSquelchWindowAgg(WindowAggState *node);

#endif   /* NODEWINDOWAGG_H */

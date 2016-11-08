/* voc 1.95 [2016/11/08]. Bootstrapping compiler for address size 8, alignment 8. xtspaSfF */

#ifndef Out__h
#define Out__h

#include "SYSTEM.h"




import void Out_Char (CHAR ch);
import void Out_Flush (void);
import void Out_Int (INT64 x, INT64 n);
import void Out_Ln (void);
import void Out_LongReal (LONGREAL x, INT16 n);
import void Out_Open (void);
import void Out_Real (REAL x, INT16 n);
import void Out_String (CHAR *str, LONGINT str__len);
import LONGREAL Out_Ten (INT16 e);
import void *Out__init(void);


#endif // Out
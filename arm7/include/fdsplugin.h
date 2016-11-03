/*                   */
/* FDS souce plug-in */
/*                   */
typedef	unsigned char	BYTE;
typedef	unsigned short	WORD;
typedef	signed int	INT;
typedef	void*		HFDS;

/* Function pointer prototypes */
/* Create */
typedef	HFDS ( *FDSCREATE )();
/* Close */
typedef	void ( *FDSCLOSE  )( HFDS );

/* Reset */
typedef	void ( *FDSRESET  )( HFDS, INT );
/* Setup */
typedef	void ( *FDSSETUP  )( HFDS, INT );
/* Write */
typedef	void ( *FDSWRITE  )( HFDS, WORD, BYTE );
/* Read */
typedef	BYTE ( *FDSREAD   )( HFDS, WORD );

/* Get PCM data */
typedef	INT  ( *FDSPROCESS)( HFDS );
/* Get FDS frequency */
typedef	INT  ( *FDSGETFREQ)( HFDS );

/* Write */
typedef	void ( *FDSWRITESYNC)( HFDS, WORD, BYTE );
/* Read */
typedef	BYTE ( *FDSREADSYNC)( HFDS, WORD );
/* Sync */
typedef	void ( *FDSSYNC   )( HFDS, INT );


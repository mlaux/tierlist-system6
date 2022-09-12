unit Types;

interface

	type
		SongInfo = packed record
				version: integer;
				title: string[63];
				artist: string[63];
				genre: string[63];
				titlePict: integer;
				artistPict: integer;
				genrePict: integer;
				tier: string[3];
				indDiff: boolean;
				bpm: string[15];
				noteCount: integer;
				radarType: string[15];
			end;
		SongPtr = ^SongInfo;
		SongInfoList = packed record
				count: integer;
				songs: array[0..0] of SongInfo;
			end;
		SongListPtr = ^SongInfoList;
		SongListHandle = ^SongListPtr;

	const
		CELL_HEIGHT = 32;

implementation

end.
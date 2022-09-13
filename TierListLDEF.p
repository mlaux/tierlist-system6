unit TierListLDEF;

interface

	uses
		Types;

	procedure main (message: integer;
									selected: boolean;
									var cellRect: Rect;
									theCell: Cell;
									dataOffset: integer;
									dataLen: integer;
									theList: ListHandle);

implementation

	procedure DrawPictResource (id: integer;
									cellRect: Rect);
		var
			pictRes: PicHandle;
			rct: Rect;
	begin
		pictRes := PicHandle(GetResource('PICT', id));
		rct := cellRect;
		rct.bottom := rct.top + pictRes^^.picFrame.bottom;
		rct.right := rct.left + pictRes^^.picFrame.right;
		OffsetRect(rct, 20, 1);
		DrawPicture(pictRes, rct);
		ReleaseResource(Handle(pictRes));
	end;

	procedure main (message: integer;
									selected: boolean;
									var cellRect: Rect;
									theCell: Cell;
									dataOffset: integer;
									dataLen: integer;
									theList: ListHandle);
		label
			1;

		var
			savedPort: GrafPtr;
			savedClip: RgnHandle;
			savedPenState: PenState;
			savedFont: integer;
			songData: SongListHandle;
			offset: longint;
			temp: SongPtr;
			song: SongInfo;

	begin
		if message = lHiliteMsg then
			begin
				InvertRect(cellRect);
			end;
		if message <> lDrawMsg then
			goto 1;

		GetPort(savedPort);
		SetPort(theList^^.port);
		savedClip := NewRgn;
		GetClip(savedClip);
		ClipRect(cellRect);
		GetPenState(savedPenState);
		savedFont := theList^^.port^.txFont;

		PenNormal;
		TextFont(systemFont);

		LGetCell(@songData, dataLen, theCell, theList);

{ song list can be larger than 32k so array index won't work }
		offset := longint(theCell.v) * sizeof(SongInfo);
		temp := SongPtr(longint(@songData^^.songs) + offset);
		song := temp^;

		EraseRect(cellRect);
{ FrameRect(cellRect); }

		MoveTo(cellRect.left + 4, cellRect.top + 22);
		DrawString(song.tier);

		if song.titlePict <> 0 then
			DrawPictResource(song.titlePict, cellRect)
		else
			begin
				MoveTo(cellRect.left + 20, cellRect.top + 14);
				DrawString(song.title);
			end;

		TextFont(geneva);
		MoveTo(cellRect.left + 20, cellRect.top + 28);
		DrawString('no play, score: 0');

		if selected then
			InvertRect(cellRect);

		SetPort(savedPort);
		SetClip(savedClip);
		DisposeRgn(savedClip);
		SetPenState(savedPenState);
		TextFont(savedFont);

1:
		;
	end;
end.
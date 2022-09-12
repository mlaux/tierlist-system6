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
		rct.top := rct.top + 48 - pictRes^^.picFrame.bottom;
		rct.right := rct.left + pictRes^^.picFrame.right;
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
			songData: SongListHandle;
			song: SongInfo;

	begin
		if message <> lDrawMsg then
			goto 1;

		GetPort(savedPort);
		SetPort(theList^^.port);
		savedClip := NewRgn;
		GetClip(savedClip);
		ClipRect(cellRect);
		GetPenState(savedPenState);
		PenNormal;

		LGetCell(@songData, dataLen, theCell, theList);
		song := songData^^.songs[theCell.v];

		EraseRect(cellRect);
		FrameRect(cellRect);
		MoveTo(cellRect.left, cellRect.bottom);
		if song.titlePict <> 0 then
			DrawPictResource(song.titlePict, cellRect)
		else
			DrawString(song.title);

		SetPort(savedPort);
		SetClip(savedClip);
		DisposeRgn(savedClip);
		SetPenState(savedPenState);

1:
		;
	end;
end.
program TierList;

	uses
		Types;

	const
		MENU_APPLE = 128;
		MENU_FILE = 129;
		MBAR_MAIN = 128;

		SLST_12 = 128;
		DLOG_MAIN = 128;

		ITEM_FILTER = 2;
		ITEM_LIST = 3;
		ITEM_TITLE_PICT = 21;
		ITEM_ARTIST_PICT = 22;
		ITEM_GENRE_PICT = 23;
		ITEM_TITLE_TEXT = 24;
		ITEM_ARTIST_TEXT = 25;
		ITEM_GENRE_TEXT = 26;
		ITEM_BPM_TEXT = 28;
		ITEM_NOTES_TEXT = 29;
		ITEM_TIER_TEXT = 30;

		LDEF_SONGS = 128;

	var
		mainWindow: DialogPtr;
		songData: SongListHandle;
		songListControl: ListHandle;
		gotEvent: boolean;
		evt: EventRecord;
		evtDialog: DialogPtr;
		itemHit: integer;
		handled: boolean;
		done: boolean;

	function LoadSongData: SongListHandle;
		var
			listRes: SongListHandle;
			rowNum: integer;
			cell: Point;
	begin
		listRes := SongListHandle(GetResource('slst', SLST_12));
		rowNum := 0;
		rowNum := LAddRow(listRes^^.count, 0, songListControl);
		for rowNum := 0 to listRes^^.count - 1 do
			begin
				SetPt(cell, 0, rowNum);
				LSetCell(@listRes, 4, cell, songListControl);
			end;

		LoadSongData := listRes;
	end;

	procedure PopulateMenus;
		var
			appleMenu: MenuHandle;
	begin
		appleMenu := GetMenu(MENU_APPLE);
		AddResMenu(appleMenu, 'DRVR');
		InsertMenu(appleMenu, 0);
		InsertMenu(GetMenu(MENU_FILE), 0);
		DrawMenuBar;
	end;

	procedure InitToolbox;
	begin
		InitGraf(@thePort);
		InitFonts;
		FlushEvents(everyEvent, 0);
		InitWindows;
		InitMenus;
		TEInit;
		InitDialogs(nil);
		InitCursor;
	end;

	procedure SwapTextOrPict (text: string;
									pictId: integer;
									textItemId: integer;
									pictItemId: integer);
		var
			itemType: integer;
			itemHandle: Handle;
			pict: PicHandle;
			itemRect: Rect;
	begin
		if pictId <> 0 then
			begin
				HideDItem(mainWindow, textItemId);

{ really only need the rect from this call }
				GetDItem(mainWindow, pictItemId, itemType, itemHandle, itemRect);

				pict := PicHandle(GetResource('PICT', pictId));
				itemRect.right := itemRect.left + pict^^.picFrame.right;
				itemRect.bottom := itemRect.top + pict^^.picFrame.bottom;
				SetDItem(mainWindow, pictItemId, picItem, Handle(pict), itemRect);
				ShowDItem(mainWindow, pictItemId);
			end
		else
			begin
				HideDItem(mainWindow, pictItemId);

				GetDItem(mainWindow, textItemId, itemType, itemHandle, itemRect);
				SetIText(itemHandle, text);
				ShowDItem(mainWindow, textItemId);
			end;
	end;

	procedure SetItemText (id: integer;
									text: string);
		var
			itemType: integer;
			itemHandle: Handle;
			itemRect: Rect;
	begin
		GetDItem(mainWindow, id, itemType, itemHandle, itemRect);
		SetIText(itemHandle, text);
	end;

	procedure UpdateSelectedSong;
		label
			1;
		var
			song: SongInfo;
			theCell: Cell;
			itemType: integer;
			itemHandle: Handle;
			itemRect: Rect;
	begin
		theCell.h := 0;
		theCell.v := 0;
		if not LGetSelect(true, theCell, songListControl) then
			goto 1;

		song := songData^^.songs[theCell.v];

		SwapTextOrPict(song.title, song.titlePict, ITEM_TITLE_TEXT, ITEM_TITLE_PICT);
		SwapTextOrPict(song.artist, song.artistPict, ITEM_ARTIST_TEXT, ITEM_ARTIST_PICT);
		SwapTextOrPict(song.genre, song.genrePict, ITEM_GENRE_TEXT, ITEM_GENRE_PICT);

		SetItemText(ITEM_BPM_TEXT, song.bpm);
		SetItemText(ITEM_NOTES_TEXT, StringOf(song.noteCount : 1));
		SetItemText(ITEM_TIER_TEXT, song.tier);

		GetDItem(mainWindow, ITEM_GENRE_TEXT, itemType, itemHandle, itemRect);
		GetDItem(mainWindow, ITEM_TIER_TEXT, itemType, itemHandle, itemRect);
1:
	end;

	procedure HandleMenuItem (selectResult: longint);
	begin
		HiliteMenu(0);
	end;

	procedure HandleMouseDown (evt: EventRecord);
		var
			evtWindow: WindowPtr;
			shouldQuit: boolean;
			temp: boolean;
	begin
		case FindWindow(evt.where, evtWindow) of
			inSysWindow: 
				SystemClick(evt, evtWindow);
			inMenuBar: 
				HandleMenuItem(MenuSelect(evt.where));
			inDrag: 
				DragWindow(evtWindow, evt.where, GetGrayRgn^^.rgnBBox);
			inGoAway: 
				done := TrackGoAway(evtWindow, evt.where);
			otherwise
				begin
					if PtInRect(evt.where, songListControl^^.rView) then
						begin
							SetPort(songListControl^^.port);
							GlobalToLocal(evt.where);
							temp := LClick(evt.where, evt.modifiers, songListControl);
						end;
				end;
		end;
	end;

	procedure HandleMouseUp (evt: EventRecord);
		var
			evtWindow: WindowPtr;
	begin
		if PtInRect(evt.where, songListControl^^.rView) then
			UpdateSelectedSong;
	end;

	procedure SetInitialVisibility (dialog: DialogPtr);
	begin

		HideDItem(mainWindow, ITEM_TITLE_TEXT);
		HideDItem(mainWindow, ITEM_ARTIST_TEXT);
		HideDItem(mainWindow, ITEM_GENRE_TEXT);
		HideDItem(mainWindow, ITEM_TITLE_PICT);
		HideDItem(mainWindow, ITEM_ARTIST_PICT);
		HideDItem(mainWindow, ITEM_GENRE_PICT);
	end;

	function CreateSongList (dialog: DialogPtr;
									itemNumber: integer): ListHandle;
		var
			itemType: integer;
			itemHandle: Handle;
			listRect: Rect;
			dataBounds: Rect;
			cellSize: Point;
	begin
		GetDItem(dialog, itemNumber, itemType, itemHandle, listRect);
		SetRect(dataBounds, 0, 0, 1, 0); { 1 column }
		SetPt(cellSize, 0, CELL_HEIGHT);
		listRect.right := listRect.right - 15; { scroll bar is 15 px wide }

{ boolean params: autodraw, has grow box, scroll horizontally, scroll vertically }
		CreateSongList := LNew(listRect, dataBounds, cellSize, LDEF_SONGS, dialog, true, false, false, true);
	end;

	procedure DrawSongListBorder (list: ListHandle);
		var
			border: Rect;
			pnState: PenState;
	begin
		border := list^^.rView;
		GetPenState(pnState);
		PenSize(1, 1);
		InsetRect(border, -1, -1);
		FrameRect(border);
		SetPenState(pnState);
	end;

begin
	InitToolbox;
	PopulateMenus;
	mainWindow := GetNewDialog(DLOG_MAIN, nil, pointer(-1));
	SetInitialVisibility(mainWindow);
	songListControl := CreateSongList(mainWindow, ITEM_LIST);
	songData := LoadSongData;
	ShowWindow(mainWindow);
	done := false;

	repeat
		SystemTask;

		gotEvent := GetNextEvent(everyEvent, evt);

{ have to call IsDialogEvent even if gotEvent is false }
		if IsDialogEvent(evt) then
			handled := DialogSelect(evt, evtDialog, itemHit);

		if gotEvent then
			case evt.what of
				mouseDown: 
					HandleMouseDown(evt);
				mouseUp: 
					HandleMouseUp(evt);
				activateEvt: 
					begin
						if BitAnd(evt.modifiers, activeFlag) <> 0 then
							begin
								LActivate(true, songListControl);
							end
						else
							begin
								LActivate(false, songListControl);
							end;
					end;
				updateEvt: 
					begin
			{ not calling BeginUpdate/EndUpdate because DialogSelect already did }
						SetPort(songListControl^^.port);
						LUpdate(songListControl^^.port^.visRgn, songListControl);
						DrawSongListBorder(songListControl);
					end;
			end;

	until done;

	LDispose(songListControl);
	DisposDialog(mainWindow);
end.
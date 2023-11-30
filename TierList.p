program TierList;

	uses
		Types;

	const
		FILE_DLG_WIDTH = 348;

		MENU_APPLE = 128;
		MENU_FILE = 129;
		MBAR_MAIN = 128;

		MENU_ITEM_OPEN = 1;
		MENU_ITEM_SAVE = 2;
		MENU_ITEM_QUIT = 4;

{ resource ID of 12 list }
		SLST_12 = 128;

		DLOG_MAIN = 128;

{ the main song list's index in the DITL }
		ITEM_LIST = 1;

{ radio buttons }
		ITEM_NO_PLAY = 9;
		ITEM_FAILED = 10;
		ITEM_ASSIST = 11;
		ITEM_EASY = 12;
		ITEM_CLEAR = 13;
		ITEM_HARD = 14;
		ITEM_EX_HARD = 15;
		ITEM_FULL_COMBO = 16;

{ song details }
		ITEM_TITLE_PICT = 19;
		ITEM_ARTIST_PICT = 20;
		ITEM_GENRE_PICT = 21;
		ITEM_TITLE_TEXT = 22;
		ITEM_ARTIST_TEXT = 23;
		ITEM_GENRE_TEXT = 24;
		ITEM_BPM_TEXT = 26;
		ITEM_NOTES_TEXT = 27;
		ITEM_TIER_TEXT = 28;
		ITEM_VERSION_TEXT = 32;

{ text fields }
		ITEM_SCORE_INPUT = 18;
		ITEM_BP_INPUT = 30;
		ITEM_SAVE_BUTTON = 25;


{ resource ID of list cell drawing procedure }
		LDEF_SONGS = 128;

	var
		appleMenu: MenuHandle;
		mainWindow: DialogPtr;
		songData: SongListHandle;
		songListControl: ListHandle;
		scoreData: ScoreListPtr;
		visibleSongs: IntegerPtr;
		currentFile: Str255;
		gotEvent: boolean;
		evt: EventRecord;
		evtDialog: DialogPtr;
		itemHit: integer;
		handled: boolean;
		done: boolean;

	procedure AddSongRows;
		var
			listRes: SongListHandle;
			rowNum: integer;
			cell: Point;
			cellData: ListCellData;
	begin
		cellData.songData := songData;
		cellData.scoreData := scoreData;

		rowNum := LAddRow(songData^^.count, 0, songListControl);
		for rowNum := 0 to songData^^.count - 1 do
			begin
				SetPt(cell, 0, rowNum);
				LSetCell(@cellData, sizeof(cellData), cell, songListControl);
			end;

		LDoDraw(true, songListControl);
	end;

	procedure PopulateMenus;
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

{ I don't know if this erase/inval strategy is correct but it seems to work }
				EraseRect(itemRect);

				pict := GetPicture(pictId);
				itemRect.right := itemRect.left + pict^^.picFrame.right;
				itemRect.bottom := itemRect.top + pict^^.picFrame.bottom;
				SetDItem(mainWindow, pictItemId, picItem, Handle(pict), itemRect);
				ShowDItem(mainWindow, pictItemId);

{ and here }
				InvalRect(itemRect);
			end
		else
			begin
				HideDItem(mainWindow, pictItemId);

				GetDItem(mainWindow, textItemId, itemType, itemHandle, itemRect);
				SetIText(itemHandle, text);
				ShowDItem(mainWindow, textItemId);
			end;

		BeginUpdate(mainWindow);
		UpdateDialog(mainWindow, mainWindow^.visRgn);
		EndUpdate(mainWindow);
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

	procedure RadioSelect (first, last, selection: integer);
		var
			k: integer;
			itemType: integer;
			item: Handle;
			rct: Rect;
	begin
		for k := ITEM_NO_PLAY to ITEM_FULL_COMBO do
			begin
				GetDItem(mainWindow, k, itemType, item, rct);
				SetCtlValue(ControlHandle(item), 0);
			end;

		GetDItem(mainWindow, selection, itemType, item, rct);
		SetCtlValue(ControlHandle(item), 1);
	end;

	procedure SetEditTextInt (textId: integer;
									value: integer);
		var
			itemType: integer;
			item: Handle;
			rct: Rect;
	begin
		GetDItem(mainWindow, textId, itemType, item, rct);
		SetIText(item, StringOf(value : 1));
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
			offset: longint;
			temp: SongPtr;
			theScore: Score;
	begin
		theCell.h := 0;
		theCell.v := 0;
		if not LGetSelect(true, theCell, songListControl) then
			goto 1;

{ need to do a 32-bit offset here }
		offset := longint(theCell.v) * sizeof(SongInfo);
		temp := SongPtr(longint(@songData^^.songs) + offset);
		song := temp^;

		SwapTextOrPict(song.title, song.titlePict, ITEM_TITLE_TEXT, ITEM_TITLE_PICT);
		SwapTextOrPict(song.artist, song.artistPict, ITEM_ARTIST_TEXT, ITEM_ARTIST_PICT);
		SwapTextOrPict(song.genre, song.genrePict, ITEM_GENRE_TEXT, ITEM_GENRE_PICT);

		SetItemText(ITEM_BPM_TEXT, song.bpm);
		SetItemText(ITEM_NOTES_TEXT, StringOf(song.noteCount : 1));
		SetItemText(ITEM_TIER_TEXT, StringOf(song.tier, ' (', song.radarType, ')'));
		SetItemText(ITEM_VERSION_TEXT, StringOf(song.version : 1));

		theScore := scoreData^.scores[theCell.v];
		RadioSelect(ITEM_NO_PLAY, ITEM_FULL_COMBO, theScore.clearLamp + ITEM_NO_PLAY);

		SetEditTextInt(ITEM_SCORE_INPUT, theScore.exScore);
		SetEditTextInt(ITEM_BP_INPUT, theScore.missCount);
1:
	end;

	procedure ShowSaveDialog;
		var
			pt: Point;
			reply: SFReply;
			err: OSErr;
			fileNo: integer;
			count: longint;
		label
			1;
	begin
		pt.h := screenBits.bounds.right div 2 - FILE_DLG_WIDTH div 2;
		pt.v := 0;
		fileNo := 0;

		SFPutFile(pt, '', currentFile, nil, reply);
		if not reply.good then
			goto 1;

		err := FSOpen(reply.fName, reply.vRefNum, fileNo);
		if err <> 0 then
			if err <> fnfErr then
				goto 1
			else
				begin
					err := Create(reply.fName, reply.vRefNum, 'IIDX', 'djpf');
					if err <> noErr then
						goto 1;
					err := FSOpen(reply.fName, reply.vRefNum, fileNo);
					if err <> noErr then
						goto 1;
				end;

		count := sizeof(Score) * songData^^.count;
		err := FSWrite(fileNo, count, Ptr(scoreData));
		currentFile := reply.fName;

1:
		if fileNo <> 0 then
			err := FSClose(fileNo);

		DrawDialog(mainWindow);
	end;

	procedure ShowOpenDialog;
		var
			pt: Point;
			types: SFTypeList;
			reply: SFReply;
			fileNo: integer;
			err: OSErr;
			fileSize: longint;
			amountRead: longint;
			contents: Handle;
		label
			1;
	begin
		pt.h := screenBits.bounds.right div 2 - FILE_DLG_WIDTH div 2;
		pt.v := 0;
		fileNo := 0;

		types[0] := 'djpf';
		SFGetFile(pt, '', nil, 1, types, nil, reply);

		if not reply.good then
			goto 1;

		err := FSOpen(reply.fName, reply.vRefNum, fileNo);
		if err <> noErr then
			goto 1;

		err := GetEOF(fileNo, fileSize);
		if (err <> noErr) or (fileSize > (sizeof(Score) * songData^^.count)) then
			goto 1;

		amountRead := fileSize;
		err := FSRead(fileNo, amountRead, Ptr(scoreData));
		if (err <> noErr) or (amountRead <> fileSize) then
			goto 1;

		UpdateSelectedSong;
		LUpdate(songListControl^^.port^.visRgn, songListControl);
		currentFile := reply.fName;

1:
		if fileNo <> 0 then
			err := FSClose(fileNo);

		DrawDialog(mainWindow);
	end;

	procedure HandleMenuItem (selectResult: longint);
		var
			menuNum: integer;
			menuItem: integer;
			itemName: Str255;
			temp: integer;
	begin
		menuNum := HiWord(selectResult);
		menuItem := LoWord(selectResult);

		case menuNum of
			MENU_APPLE: 
				begin
					GetItem(appleMenu, menuItem, itemName);
					temp := OpenDeskAcc(itemName);
					SetPort(mainWindow);
				end;
			MENU_FILE: 
				case menuItem of
					MENU_ITEM_OPEN: 
						ShowOpenDialog;
					MENU_ITEM_SAVE: 
						ShowSaveDialog;
					MENU_ITEM_QUIT: 
						done := true;
				end;
		end;
		HiliteMenu(0);
	end;

	procedure HandleMouseDown (evt: EventRecord);
		var
			evtWindow: WindowPtr;
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
					GlobalToLocal(evt.where);
					temp := LClick(evt.where, evt.modifiers, songListControl);
				end;
		end;
	end;

	procedure HandleMouseUp (evt: EventRecord);
		var
			evtWindow: WindowPtr;
	begin
		GlobalToLocal(evt.where);
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
		CreateSongList := LNew(listRect, dataBounds, cellSize, LDEF_SONGS, dialog, false, false, false, true);
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

	procedure HandleClearLamp (itemId: integer);
		var
			theCell: Cell;
		label
			1;
	begin
		theCell.h := 0;
		theCell.v := 0;

{ if nothing is selected, do nothing }
		if not LGetSelect(true, theCell, songListControl) then
			goto 1;

		RadioSelect(ITEM_NO_PLAY, ITEM_FULL_COMBO, itemId);

		scoreData^.scores[theCell.v].clearLamp := itemId - ITEM_NO_PLAY;

		LUpdate(songListControl^^.port^.visRgn, songListControl);
1:
	end;

	function ReadEditText (textId: integer): integer;
		var
			itemType: integer;
			item: Handle;
			rct: Rect;
			theText: Str255;
			value: integer;
		label
			1;
	begin
		GetDItem(mainWindow, textId, itemType, item, rct);
		GetIText(item, theText);
		if length(theText) > 4 then
			goto 1;
		ReadString(theText, value);
		if (IOResult <> 0) or (value < 0) then
			goto 1;

		ReadEditText := value;
		exit(ReadEditText);

1:
		ReadEditText := 0;
	end;

	procedure CommitScore;
		var
			theCell: Cell;
			exScore: integer;
			missCount: integer;
		label
			1;
	begin
		theCell.h := 0;
		theCell.v := 0;

		if not LGetSelect(true, theCell, songListControl) then
			goto 1;

		exScore := ReadEditText(ITEM_SCORE_INPUT);
		scoreData^.scores[theCell.v].exScore := exScore;

		missCount := ReadEditText(ITEM_BP_INPUT);
		scoreData^.scores[theCell.v].missCount := missCount;

{ can I just call this wherever? }
		LUpdate(songListControl^^.port^.visRgn, songListControl);
1:
	end;

	procedure InitVisibleSongs;
		var
			k: integer;
			p: IntegerPtr;
			ret: IntegerPtr;
	begin
		visibleSongs := IntegerPtr(NewPtrClear(songData^^.count * sizeof(integer)));
		p := visibleSongs;
		for k := 0 to songData^^.count - 1 do
			begin
				p^ := k;
				p := pointer(ord4(p) + 2);
			end;
	end;

	procedure HandleDialogItem (itemId: integer);
	begin
		if (itemId >= ITEM_NO_PLAY) and (itemId <= ITEM_FULL_COMBO) then
			HandleClearLamp(itemId);

		if itemId = ITEM_SAVE_BUTTON then
			CommitScore;
	end;

begin
{ handle errors by checking IOResult instead of just crashing }
	IOCheck(false);

	InitToolbox;
	PopulateMenus;
	mainWindow := GetNewDialog(DLOG_MAIN, nil, pointer(-1));
	SetInitialVisibility(mainWindow);
	songData := SongListHandle(GetResource('slst', SLST_12));
	InitVisibleSongs;
	scoreData := ScoreListPtr(NewPtrClear(songData^^.count * sizeof(Score)));
	songListControl := CreateSongList(mainWindow, ITEM_LIST);
	AddSongRows;

	ShowWindow(mainWindow);

	done := false;
	currentFile := '';

	repeat
		SystemTask;

		gotEvent := GetNextEvent(everyEvent, evt);

{ have to call IsDialogEvent even if gotEvent is false }
		if IsDialogEvent(evt) then
			handled := DialogSelect(evt, evtDialog, itemHit);

		if itemHit <> -1 then
			HandleDialogItem(itemHit);

		if gotEvent then
			case evt.what of
				mouseDown: 
					HandleMouseDown(evt);
				mouseUp: 
					HandleMouseUp(evt);
				activateEvt: 
					begin
						if BitAnd(evt.modifiers, activeFlag) <> 0 then
							LActivate(true, songListControl)
						else
							LActivate(false, songListControl);
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
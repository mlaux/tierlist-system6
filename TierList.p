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

	end;

	function CreateSongList (dialog: DialogPtr; itemNumber: integer): ListHandle;
		var
			itemType: integer;
			itemHandle: Handle;
			listRect: Rect;
			dataBounds: Rect;
			cellSize: Point;
	begin
		GetDItem(dialog, itemNumber, itemType, itemHandle, listRect);
		SetRect(dataBounds, 0, 0, 1, 0); { 1 column }
		SetPt(cellSize, 0, 48);
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
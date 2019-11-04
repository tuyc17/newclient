; merge��
.386
.model flat, stdcall
option casemap :none   

include		windows.inc
include		user32.inc
includelib	user32.lib
include		kernel32.inc
includelib	kernel32.lib
include		wsock32.inc
includelib	wsock32.lib
include MSVCRT.inc
includelib MSVCRT.lib

FLAG_LOGIN		equ	0
FLAG_LOGON	equ	1
FLAG_MAIN		equ	2
FLAG_EXIT		equ	3

DLG_MAIN	equ	1000
DLG_LOGIN	equ	1001
DLG_LOGON		equ	1002

IDC_ADD		equ		1005
IDC_FRIENDLIST equ 1006
IDC_SERVER	equ	2000
IDC_INFO	equ	2001
IDC_TEXT	equ	2002
IDC_USERNAME equ 2003
IDC_PASSWORD equ 2004
IDC_NICKNAME equ 2005
IDC_NEWNAME	equ	2006
IDC_ONPASS		equ	2008

IDLOGIN	equ	3001
IDLOGON	equ	3002
IDRENAME	equ	3003
IDADDFRIEND	equ	3004
IDSURE		equ		3005
IDBACK		equ		3006

WM_SOCKET       equ	WM_USER + 100
UDP_PORT	equ	6789
TCP_PORT	equ	9876
;������214��׼ͨѶЭ��

;������
RID_ADDFRIEND	equ 30303030h
RID_GETMES	equ 32303030h
RID_GETPIC	equ 33303030h
RID_RENAME	equ 34303030h
RID_LOGIN	equ 35303030h
RID_LOGON	equ 36303030h
RID_GETNAME equ 37303030h
RID_FRIENDLIST	equ 61303030h
RID_DELETEFRIEND	equ 62303030h
;״̬��
RID_SUCCESS equ 30303030h
RID_FAIL equ 31303030h
RID_ADDFRIEND_1 equ 31303030h
RID_ADDFRIEND_2 equ 32303030h
RID_ADDFRIEND_3 equ 33303030h

		.data
hWinMain		dd	?
hWinLogin	dd	?
hWinLogon	dd	?
hSocket		dd	?
TCPSocket		dd	?
TCPSocketPASV		dd	?
szReadBuffer	db	8192 dup (?)
address sockaddr_in <>
filedata db 32768 dup(?);�ļ���ַ��ָ������
friendlist db 32768 dup (?);һ�����ַ�������ר�ŵĺ������ڽ���
friendlength dword ?;���Ѹ���
nowname db 20 dup(0)
nowid db 5 dup(0)
peerid db 5 dup(0)
; �����л��ű�
flag	dword	FLAG_LOGIN
		.const
testname1   db  '0000',0
testname2   db  '0001',0
szIP		db	'127.0.0.1',0
szErrIP		db	'��Ч�ķ�����IP��ַ!',0
szLoginOK	db	'��¼�ɹ���', 0
szLoginFailed	db	'��¼ʧ�ܣ�', 0
szLogonOK	db	'ע��ɹ������IDΪ:', 000000000000000000000000
szLogonFailed	db	'ע��ʧ�ܣ�', 0
szAddOK		db	'��Ӻ��ѳɹ���', 0
szNotFind		db	'���޴���', 0
szFindFriend		db	'����������ĺ��ѣ�', 0
szFindSelf		db	'�����㱾�ˡ�', 0
testmesg db '1234',0
zero dword 0
szMark		db	' : ', 0
szEmp		db	' ', 0
spmodetest db '%04d',0
spmode1 db '%s',0
spmode2 db '%s%s',0
spmode3 db '%s%s%s',0
spmodeformes db '%s%s%s%s%s',0
; //////
ADDFRIEND db '0000',0
GETFRIEND db '000a',0
DELFRIEND db '000b',0
LOGOUT	db '0001',0
SENDMES	db '0002',0
SENDPIC	db '0003',0
RENAME	db '0004',0
LOGIN	db '0005',0
LOGON	db '0006',0
GETNAME	db '0007',0

; ��¼���洰������������ȡ���
szTitle	db	'���¼', 0
szRegist	db	'ע��', 0
; ��½������ʾ
szWord1	db	'�������û���', 0
szWord2	db	'����������', 0
; ��������������
szItem1	db	'0001 : Jason������', 0
szItem2	db	'0002 : �ϰ���Ұ����', 0
; �������û��ǳ�
szNick	db	'tempname', 0
; �����������¼·���Լ��ļ��򿪷�ʽ�Լ�����д�����Ϣ
szPath1		db	'ChatHistory/', 0
szPath2		db	'.txt', 0
tempPath	db	'ChatHistory/histor.txt', 0
szLine	db	'_', 0

szMode_a	db	'a', 0
szMode_rb db 'rb+',0

dwReturn	dd	-1
testcommand db  '12345678',0

		.code

_SendCommand	proc uses eax ecx command
		invoke	RtlZeroMemory,addr address,sizeof address
		invoke	inet_addr,addr szIP
		mov	address.sin_addr,eax
		mov	address.sin_family,AF_INET
		invoke	htons,UDP_PORT
		mov	address.sin_port,ax
		invoke	lstrlen,command
		.if	eax
			mov	ecx, eax
			invoke	sendto, hSocket, command, ecx, 0, addr address, sizeof sockaddr_in
			.if	eax ==	SOCKET_ERROR
				invoke	WSAGetLastError
				.if	eax == WSAEWOULDBLOCK
					invoke	GetDlgItem, hWinMain, IDOK
					invoke	EnableWindow,eax,FALSE
				.endif
			.endif
		.endif
		@@:
		invoke	SetDlgItemText, hWinMain, IDC_TEXT,NULL
		ret
_SendCommand	endp



;�������к���
_DealFriendList  proc uses eax ebx
	local	@name[17] : byte
	local	@id : dword
	local @item : byte
	mov eax,offset friendlist
	; ���listbox	; ������/////////
	invoke SendDlgItemMessage, hWinMain, IDC_FRIENDLIST, LB_RESETCONTENT, 0, 0
L1:
	push ecx
	; ��friendlist����ʾ�����б�
	mov ebx,[eax]
	mov @id,ebx
	add eax,4
	invoke  crt_memmove,addr @name,eax,16
	lea eax,@name
	add eax,16
	mov ebx,offset zero
	invoke  crt_memmove,eax,ebx,1
	; �ϲ��õ�id : name
	invoke crt_sprintf, addr @item, addr spmode3, addr @id, szMark, @name
	; ��ʾ��listbox��
	invoke SendDlgItemMessage, hWinMain, IDC_FRIENDLIST, LB_ADDSTRING, 0, addr @item
	pop ecx
	dec ecx
	.if ecx==0 
		ret
	.endif

	jmp L1
	ret
_DealFriendList endp
;�Ӻ���
_AddFriend proc status
	.if status==RID_SUCCESS
		;�Ӻ��Ѳ����ɹ�
		invoke MessageBox, hWinMain, addr szAddOK, NULL, MB_OK or MB_ICONINFORMATION
		; ˢ��friend_list ; ������
		invoke _DealFriendList
	.elseif status==RID_ADDFRIEND_1
		;���޴���
		invoke MessageBox, hWinMain, addr szNotFind, NULL, MB_OK or MB_ICONHAND	
	.elseif status==RID_ADDFRIEND_2
		;����������ĺ���
		invoke MessageBox, hWinMain, addr szFindFriend, NULL, MB_OK or MB_ICONWARNING
	.elseif status==RID_ADDFRIEND_3
		;�����ǿͻ�������
		invoke MessageBox, hWinMain, addr szFindSelf, NULL, MB_OK or MB_ICONWARNING
	.endif
	ret
_AddFriend endp
;���ĺ���
_GetFriend proc	uses eax  ebx	num,list
	invoke crt_atoi,addr num
	mov ecx,eax
	push ecx
	mov ebx,20
	mul ebx
	mov num,eax

	invoke	RtlZeroMemory,addr friendlist,sizeof friendlist
	invoke  crt_memmove,addr friendlist,list,num
	pop ecx
	invoke _DealFriendList
	ret
_GetFriend endp

;ɾ������
_DeleteFriend proc id
	local @tempcommand[1024] : byte
	invoke crt_sprintf,addr @tempcommand, addr spmode3, addr DELFRIEND, nowid, id
	invoke _SendCommand ,addr @tempcommand
	ret
_DeleteFriend endp

;������Ϣ
_Getmessage proc uses eax id, len, message
	; ��id���ѷ����ĳ���Ϊlen����Ϣmessageд��ChatHistory/�µı����ļ�
	local @pathname[1024] : byte
	local @temppath[1024] : byte
	
	; ��ȡ��ʷ��¼��ַ
	invoke crt_sprintf, addr @pathname, addr spmode3, addr nowid, addr szLine, addr id
	invoke crt_sprintf, addr @temppath, addr spmode3, addr szPath1,addr @pathname, addr szPath2

	; תlen�ĸ�ʽ
	invoke crt_atoi, addr len
	mov	len,eax
	invoke crt_fopen, addr @temppath, addr szMode_a
	push eax
	invoke crt_fwrite, addr message, type message, len, eax
	pop eax
	invoke crt_fclose, eax
	ret
_Getmessage endp

;������
_Rename proc newname 
	local @str[1024]:byte
	invoke crt_sprintf,addr @str,addr spmode3,addr RENAME,addr nowid,newname
	invoke _SendCommand ,addr @str
	ret
_Rename endp

;��¼
_Login proc status
	local @tempok[1024]:byte
	.if status == RID_SUCCESS
		;��½�ɹ�
		mov ebx, FLAG_MAIN
		mov flag, ebx
		invoke  crt_memmove,addr @tempok,addr GETNAME,sizeof GETNAME
		invoke  crt_strcat,addr @tempok,addr nowid
		invoke _SendCommand ,addr @tempok
		invoke EndDialog, hWinLogin, NULL
		invoke MessageBox, hWinLogin, addr szLoginOK, NULL, MB_OK or MB_ICONINFORMATION

		; �����л����ں������
	.elseif status==RID_FAIL
		;��½ʧ��
		invoke MessageBox, hWinLogin, addr szLoginFailed, NULL, MB_OK or MB_ICONHAND
	.endif
ret
_Login endp

;ע��
_Logon proc status,id
	local @tempok[1024]:byte
	.if status==RID_SUCCESS
		invoke crt_memmove,addr nowid,addr id,4
		;ע��ɹ�����ʾ��ʾ���ڡ��޸�szLogonOK����ʾ���������ص�ע�����û���
		invoke  crt_memmove,addr @tempok,addr szLogonOK,sizeof szLogonOK
		invoke  crt_strcat,addr @tempok,addr nowid
		invoke MessageBox, hWinLogon, addr @tempok, NULL, MB_OK or MB_ICONINFORMATION

		mov ebx, FLAG_LOGIN
		mov flag, ebx
		invoke EndDialog, hWinLogon, NULL
	.elseif status==RID_FAIL
		;ע��ʧ��
		invoke MessageBox, hWinLogin, addr szLogonFailed, NULL, MB_OK or MB_ICONHAND
	.endif
	ret
_Logon endp

;post
_Post proc	uses eax

		invoke	socket,AF_INET,SOCK_STREAM,IPPROTO_TCP
		mov TCPSocket,eax
		invoke	RtlZeroMemory,addr address,sizeof address
		invoke	inet_addr,addr szIP
		mov	address.sin_addr,eax
		mov	address.sin_family,AF_INET
		invoke	htons,TCP_PORT
		mov	address.sin_port,ax
		invoke bind,TCPSocket,addr address,sizeof address
		invoke listen,TCPSocket,1
		invoke accept,TCPSocket,0,0
		mov TCPSocket,eax
		ret
_Post endp

;pasv
_Pasv proc
		invoke	socket,AF_INET,SOCK_STREAM,IPPROTO_TCP
		mov TCPSocket,eax
		invoke	RtlZeroMemory,addr address,sizeof address
		invoke	inet_addr,addr szIP
		mov	address.sin_addr,eax
		mov	address.sin_family,AF_INET
		invoke	htons,TCP_PORT
		mov	address.sin_port,ax
		invoke connect,TCPSocket,addr address,sizeof address
		ret
_Pasv endp



;���ղ�����һ��ͼƬ�ļ�������ͼƬ·����������filedata��filelengthλ��ΪͼƬ·���ַ����ĵ�ַ,ͬʱ��filelengh��һ
_Getpicture proc uses eax id,len
	local	@dwSize
	local	@stSin:sockaddr_in
	local	@picpath
	mov	@dwSize,sizeof @stSin
	;TODO:�Լ���һ��picpath:˼·ID_ID_�ڼ���ͼƬ
	
	invoke crt_atoi,addr len
	mov	len,eax
	invoke crt_fopen,@picpath,addr szMode_rb
	;��pasv
	invoke _Pasv
L3:	invoke	RtlZeroMemory,addr szReadBuffer,sizeof szReadBuffer
	invoke	recvfrom,TCPSocket,addr szReadBuffer,sizeof szReadBuffer,0,addr @stSin,addr @dwSize
	;TODO:�������ͼƬ�ļ�������
	.if eax!=0
		jmp L3
	.endif
	ret
_Getpicture endp

;����ͼƬ��Ϣ
_SendPicture  proc uses eax ebx ecx picpath,hisid
	local @fp
	local @size:dword
	local	@buffer[8192]:byte
	

	

	invoke crt_fopen,picpath,addr szMode_rb
	mov @fp,eax
	invoke GetFileSizeEx,@fp,addr @size
	invoke crt__itoa,@size,@buffer,10
	mov ebx,eax
	;TODO:��0003,ebx,myid,hisidƴ�������������

	;��port

	invoke _Post

L2:	invoke	RtlZeroMemory,addr @buffer,sizeof @buffer
	invoke crt_fread,@buffer,1,8192,@fp
	.if eax!=0
		mov	ecx,eax
		invoke	sendto,TCPSocket,@buffer,ecx,0,addr address,sizeof sockaddr_in
		jmp L2
	.endif
	;Ȼ��ر�socket

	invoke	closesocket,TCPSocket
	ret
_SendPicture endp
;��������


_GetName proc uses eax ebx myname
	invoke crt_memmove,addr nowname,myname,16
	invoke crt_strchr,addr nowname,93
	.if eax!=0
		invoke crt_memmove,eax,addr zero,1
	.endif
	ret
_GetName endp

;������յ���Ϣ
_DealWithCommand proc uses eax ebx edx edi esi command
		mov esi,command
		mov eax,[esi]
		.if eax==RID_ADDFRIEND
			add esi,4
			mov ebx,[esi]
			invoke _AddFriend,ebx
			ret
		.endif
		.if eax==RID_FRIENDLIST
			add esi,4
			mov ebx,dword ptr [esi]
			add esi,4
			mov edx,esi
			invoke _GetFriend,ebx,edx
			ret
		.endif
		.if eax==RID_DELETEFRIEND
			add esi,4
			mov ebx,esi
			invoke _DeleteFriend,ebx
			ret
		.endif
		.if eax==RID_GETMES
			add esi,4
			mov ebx,dword ptr [esi]
			add esi,4
			mov edx,dword ptr [esi]
			add esi,4
			mov edi,esi

			invoke _Getmessage,ebx,edx,edi
			ret
		.endif
		.if eax==RID_GETPIC
			add esi,4
			mov ebx,dword ptr [esi]
			add esi,4
			mov edx,dword ptr [esi]
			invoke _Pasv
			invoke _Getpicture,ebx,edx
			ret
		.endif
		.if eax==RID_RENAME
			add esi,4
			mov ebx,esi
			invoke _GetName,ebx
			ret
		.endif
		.if eax==RID_LOGIN
			add esi,4
			mov ebx,dword ptr [esi]
			invoke _Login,ebx
			ret
		.endif
		.if eax==RID_LOGON
			add esi,4
			mov ebx,dword ptr [esi]
			add esi,4
			mov edx,dword ptr [esi]
			invoke _Logon,ebx,edx
			ret
		.endif
		.if eax==RID_GETNAME
			add esi,4
			mov edx,esi
			invoke _GetName,edx
			ret
		.endif
		ret
_DealWithCommand endp	

;��ʱ�������ڲ��ԣ�֮��Ҫɾ--------------------
_RecvData	proc	_hSocket
		local	@dwRecv,@dwSize
		local	@stSin:sockaddr_in
		local   @command:dword
		mov	@dwSize,sizeof @stSin
		invoke	RtlZeroMemory,addr szReadBuffer,sizeof szReadBuffer
		invoke	RtlZeroMemory,addr @stSin,sizeof @stSin
		invoke	recvfrom,_hSocket,addr szReadBuffer,sizeof szReadBuffer,\
			0,addr @stSin,addr @dwSize
		;��������Ų16λ�������������
		mov esi,offset szReadBuffer
		mov edx,[esi]
		invoke _DealWithCommand,esi
		push esi
		.if	eax !=	SOCKET_ERROR
			.if	eax ==	SOCKET_ERROR
				invoke	WSAGetLastError
				.if	eax == WSAEWOULDBLOCK
					invoke	GetDlgItem,hWinMain,IDOK
					invoke	EnableWindow,eax,FALSE
				.endif
			.endif
			invoke	GetDlgItem,hWinMain,IDC_INFO
			mov	ebx,eax
			invoke	GetWindowTextLength,ebx
			invoke	SendMessage,ebx,EM_SETSEL,eax,eax
			pop esi
			invoke	SendMessage,ebx,EM_REPLACESEL,FALSE,esi
		.endif
		ret

_RecvData	endp

; ��ʼ�� Socket
_Init		proc
		local	@stWsa:WSADATA
		invoke	closesocket,hSocket
		invoke	WSAStartup,101h,addr @stWsa
		invoke	socket,AF_INET,SOCK_DGRAM,0
		mov	hSocket,eax
		invoke	WSAAsyncSelect,hSocket,hWinMain,WM_SOCKET,FD_READ or FD_WRITE
		invoke	WSAAsyncSelect,hSocket,hWinLogin,WM_SOCKET,FD_READ or FD_WRITE
		invoke	WSAAsyncSelect,hSocket,hWinLogon,WM_SOCKET,FD_READ or FD_WRITE
		ret

_Init		endp

;	�����ڳ���
_ProcDlgMain	proc	uses ebx edi esi hWnd,wMsg,wParam,lParam
		local	@tempcommand[1024]:byte
		local @addcommand[1024] : byte
		local @tempname[1024] : byte
		local @tempmes[1024] : byte
		local @tempword[1024] : byte ; fread�洢�����¼����ʱ����
		local @tempitem[1024] : byte	; ������˫�����б�item
		local @tempid : dword	; ��ѡ��item��id		; ����������ȫ�ֱ�����
		local @pathname[9] : byte
		local @temppath[1024] : byte	; ��ʷ��¼��ַ
		local @newfriend[1024] : byte	; ��Ѱ�º��ѵ�id
		local @tempdw:dword

		mov	eax,wMsg
;********************************************************************
		.if	eax ==	WM_SOCKET
			mov	eax,lParam
			.if	ax ==	FD_READ
				invoke	_RecvData,wParam
			.elseif	ax ==	FD_WRITE
				invoke	GetDlgItem,hWnd,IDOK
				invoke	EnableWindow,eax,TRUE
			.endif
;********************************************************************
		.elseif	eax ==	WM_COMMAND
			mov	eax,wParam
			; �����͡���ť
			.if	ax ==	IDOK
				push eax
				
				invoke	GetDlgItemText, hWinMain, IDC_TEXT, addr @tempcommand, sizeof @tempcommand

				
				mov @tempdw,eax
				invoke crt_sprintf,addr @tempname,addr spmodetest,@tempdw
				invoke crt_sprintf,addr @tempmes,addr spmodeformes,addr SENDMES,addr nowid,addr peerid,addr @tempname,addr @tempcommand
				invoke	_SendCommand,addr @tempmes
				pop eax
			; ������������ť
			.elseif ax == IDRENAME
				invoke crt_memset,addr @tempname,93,16		
				invoke GetDlgItemText, hWinMain, IDC_NEWNAME, addr @tempname, sizeof @tempname
				lea edx,@tempname
				add edx,eax
				.if eax!=16
					invoke crt_memset,edx,93,1
				.endif
				invoke _Rename, addr @tempname
			; ����Ӻ��ѡ���ť
			.elseif ax == IDADDFRIEND
				; ��ȡIDC_ADD�е�ID
				invoke GetDlgItemText, hWinMain, IDC_ADD, addr @newfriend, sizeof @newfriend
				; ����command
				invoke crt_sprintf,addr @addcommand, addr spmode3, addr ADDFRIEND, nowid, @newfriend
				invoke _SendCommand ,addr @addcommand
			; �������б���Ϣ
			.elseif ax == IDC_FRIENDLIST
				; ˫���¼�
				mov ebx, eax
				shr ebx, 16
				.if bx == LBN_DBLCLK
					; ��ȡ���ѵ�id��name
					invoke SendDlgItemMessage, hWinMain, IDC_FRIENDLIST, LB_GETCURSEL, 0, 0
					mov ebx, eax
					invoke SendDlgItemMessage, hWinMain, IDC_FRIENDLIST, LB_GETTEXT, ebx, addr @tempitem
					; �ֽ�@tempitem����ȡǰ4λ�õ�@tempid
					mov ebx, dword ptr @tempitem
					mov @tempid, ebx
					lea eax, @tempid
					add eax, 4
					invoke crt_memmove, eax, addr zero, 1
					invoke crt_memmove,addr peerid,addr @tempid,5
					; ��ȡ��ʷ��¼��ַ
					invoke crt_sprintf, addr @pathname, addr spmode3, addr nowid, addr szLine, addr @tempid
					invoke crt_sprintf, addr @temppath, addr spmode3, addr szPath1,addr @pathname, addr szPath2

					; invoke SetDlgItemText, hWinMain, IDC_SERVER, addr @temppath
					; ��ʾ��Ӧ�������¼
					; ��д��һ�仰��������ļ�������
					invoke crt_fopen, addr @temppath, addr szMode_a
					push eax
					invoke crt_fwrite, addr szEmp, type szEmp, 3, eax
					pop eax
					invoke crt_fclose, eax
					 
					invoke crt_fopen, addr @temppath, addr szMode_rb
					push  eax
					invoke crt_fread, addr @tempword, type @tempword, 1024, eax
					pop eax
					invoke crt_fclose, eax
					invoke SetDlgItemText, hWinMain, IDC_INFO, addr @tempword
				.endif
			.endif
;********************************************************************
		.elseif	eax ==	WM_CLOSE
			; �޸Ĵ���flag
			mov ebx, FLAG_LOGIN
			mov flag, ebx
			invoke	closesocket,hSocket
			invoke	WSACleanup
			invoke	EndDialog, hWinMain, NULL
;********************************************************************
		.elseif	eax ==	WM_INITDIALOG
			invoke	SetDlgItemText, hWinMain, IDC_SERVER, addr szIP

			push		hWnd
			pop		hWinMain

			; ////// �û��ǳƳ�ʼ��
			invoke SetDlgItemText, hWinMain, IDC_NICKNAME, addr szNick
			; �����������б��ʼ��
			invoke SendDlgItemMessage, hWinMain, IDC_FRIENDLIST, LB_ADDSTRING, 0, addr szItem1 
			invoke SendDlgItemMessage, hWinMain, IDC_FRIENDLIST, LB_ADDSTRING, 0, addr szItem2

			call	_Init
;********************************************************************
		.else
			mov	eax,FALSE
			ret
		.endif
		mov	eax,TRUE
		ret
_ProcDlgMain	endp

; ��¼���ڳ���
_ProcDlgLogin	proc uses ebx edi esi hWnd, wMsg, wParam, lParam
	local	@tempusername[1024]: byte
	local @temppassword[1024]: byte
	local @str[1024]: byte
	local @tempok[1024]: byte
	mov eax, wMsg
;********************************************************************
	.if eax == WM_COMMAND
		mov eax, wParam
		.if ax == IDLOGIN
			; ������������¼�û���������
			invoke crt_memset,addr @temppassword,93,16
			
			invoke GetDlgItemText, hWinLogin, IDC_USERNAME, addr @tempusername, sizeof @tempusername
			invoke GetDlgItemText, hWinLogin, IDC_PASSWORD, addr @temppassword, sizeof @temppassword
			push eax
			invoke crt_memmove,addr nowid,addr @tempusername,4
			pop eax
			lea edx,@temppassword
			add edx,eax
			.if eax!=16
			invoke crt_memset,edx,93,1
			.endif
			invoke crt_sprintf,addr @str,addr spmode3,addr LOGIN,addr @tempusername,addr  @temppassword
			invoke _SendCommand ,addr @str

		.elseif ax == IDLOGON
			mov ebx, FLAG_LOGON
			mov flag, ebx
			invoke EndDialog, hWinLogin, NULL
					
		.endif
	.elseif	eax ==	WM_SOCKET
			mov	eax,lParam
			.if	ax ==	FD_READ
				invoke	_RecvData,wParam
			.elseif	ax ==	FD_WRITE
				invoke	GetDlgItem,hWnd,IDOK
				invoke	EnableWindow,eax,TRUE
			.endif
;********************************************************************
	.elseif eax == WM_INITDIALOG
	; ��ȡ�����ڵľ��
		invoke FindWindow, NULL, addr szTitle
		mov hWinLogin, eax
		; ����socket
		push	hWnd
		pop		hWinLogin
		call	_Init
		
		; ��ʼ����¼����
		invoke	SetDlgItemText, hWinLogin, IDC_USERNAME,addr szWord1
		invoke	SetDlgItemText, hWinLogin, IDC_PASSWORD,addr szWord2
;********************************************************************
	.elseif eax == WM_CLOSE
		; �����˳��ű�
		mov ebx, FLAG_EXIT
		mov flag, ebx
		invoke	EndDialog, hWinLogin, NULL
;********************************************************************
	.else
		mov eax, FALSE
		ret
	.endif
	mov eax, TRUE
	ret
_ProcDlgLogin endp

; ע�ᴰ�ڳ���
_ProcDlgLogon	proc uses ebx edi esi hWnd, wMsg, wParam, lParam
	local	@temponname[1024]: byte
	local @temponpass[17]: byte
	local @str[1024]: byte
	mov eax, wMsg
;********************************************************************
	.if eax == WM_COMMAND
		mov eax, wParam
		.if ax == IDSURE
			; ����������ע������
			invoke crt_memset,addr @temponpass,93,16
			invoke crt_memset,addr @str,0,1024
			invoke GetDlgItemText, hWinLogon, IDC_ONPASS, addr @temponpass, sizeof @temponpass
			lea edx,@temponpass
			add edx, eax
			.if eax !=16
				invoke crt_memset,edx,93,1
			.endif
			invoke crt_sprintf,addr @str,addr spmode2,addr LOGON,addr @temponpass
			invoke _SendCommand ,addr @str
			
		.elseif ax == IDBACK
			mov ebx, FLAG_LOGIN
			mov flag, ebx
			invoke EndDialog, hWinLogon, NULL
		.endif
;********************************************************************
	.elseif eax == WM_INITDIALOG
		; ��ȡ�����ڵľ��
		invoke FindWindow, NULL, addr szRegist
		mov hWinLogon, eax
		; ����socket
		push	hWnd
		pop		hWinLogon
		call	_Init
		 ;��ʼ����¼����
		;invoke	SetDlgItemText, hWinLogon, IDC_USERNAME,addr szWord1
		;invoke	SetDlgItemText, hWinLogon, IDC_PASSWORD,addr szWord2
;********************************************************************
	.elseif eax == WM_CLOSE
		; �����˳��ű�
		mov ebx, FLAG_LOGIN
		mov flag, ebx
		invoke	EndDialog, hWinLogon, NULL
	.elseif	eax ==	WM_SOCKET
			mov	eax,lParam
			.if	ax ==	FD_READ
				invoke	_RecvData,wParam
			.elseif	ax ==	FD_WRITE
				invoke	GetDlgItem,hWnd,IDOK
				invoke	EnableWindow,eax,TRUE
			.endif
;********************************************************************
	.else
		mov eax, FALSE
		ret
	.endif
	mov eax, TRUE
	ret
_ProcDlgLogon endp

start:
		invoke	GetModuleHandle,NULL
DialogLoop:
		; 0����¼����
		.if flag == FLAG_LOGIN
			invoke DialogBoxParam, eax, DLG_LOGIN, NULL, offset _ProcDlgLogin, 0
		; 1��ע�����
		.elseif flag == FLAG_LOGON
			invoke DialogBoxParam, eax, DLG_LOGON, NULL, offset _ProcDlgLogon, 0
		; 2��������
		.elseif flag == FLAG_MAIN
			invoke DialogBoxParam, eax, DLG_MAIN, NULL, offset _ProcDlgMain, 0
		; 3���������
		.elseif flag == FLAG_EXIT
			JMP	Exit
		.endif
		JMP	DialogLoop
Exit:
		invoke	ExitProcess,NULL
end	start

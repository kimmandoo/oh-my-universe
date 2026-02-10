local wezterm = require 'wezterm'
local act = wezterm.action -- 키바인딩 액션을 짧게 쓰기 위한 변수
local config = wezterm.config_builder()
local home = (os.getenv('HOME') or os.getenv('USERPROFILE') or ''):gsub('\\',
                                                                        '/')
                 :gsub('/$', '')
local home_folder = home:match('([^/]+)$') or ''
-- ---------------------------------------------------------
-- [OS 설정]
-- ---------------------------------------------------------
if wezterm.target_triple:find("windows") then
    -- 기본 쉘 설정 (기본값은 Git Bash)
    local git_bash_path = 'C:\\Program Files\\Git\\bin\\bash.exe'
    local f = io.open(git_bash_path, "r")

    if f ~= nil then
        -- 1순위: Git Bash가 있으면 실행
        io.close(f)
        config.default_prog = {git_bash_path, '-i', '-l'}
    else
        -- 2순위: Git Bash가 없으면 PowerShell 실행
        config.default_prog = {'powershell.exe', '-NoLogo'}
    end
    -- config.default_prog = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-i', '-l' }

    -- 윈도우에서 선택 가능한 쉘 메뉴 구성
    config.launch_menu = {
        {
            label = 'Git Bash',
            args = {'C:\\Program Files\\Git\\bin\\bash.exe', '-i', '-l'}
        }, {label = 'PowerShell Core (pwsh)', args = {'pwsh.exe', '-NoLogo'}},
        {label = 'Windows PowerShell', args = {'powershell.exe', '-NoLogo'}},
        {label = 'Command Prompt (CMD)', args = {'cmd.exe'}}
    }
end

local CMD = "CTRL"
local OPT = "ALT"
if wezterm.target_triple:find("darwin") then
    CMD = "SUPER"
    OPT = "OPT" -- 맥에서는 명시적으로 OPT(Option) 사용
    -- 맥에서 Option 키를 눌렀을 때 특수 문자가 입력되지 않고 단축키로 작동하게 설정
    config.send_composed_key_when_left_alt_is_pressed = false
    config.send_composed_key_when_right_alt_is_pressed = false
end

-- ---------------------------------------------------------
-- [스타일] 폰트, 투명도, 창 모양 설정
-- ---------------------------------------------------------

-- 폰트 설정
config.line_height = 1.0
config.font = wezterm.font('JetBrains Mono', {weight = 'Medium'})
config.font_size = 11.0

-- 색상 테마 'Catppuccin Mocha', 'Tokyo Night', 'Dracula', 'Nord', 'Gruvbox Dark'
config.color_scheme = 'Tokyo Night'
config.window_decorations = "RESIZE" -- 윈도우 타이틀바 제거

config.window_padding = {left = 10, right = 10, top = 10, bottom = 10}
config.inactive_pane_hsb = {saturation = 0.9, brightness = 0.7}
config.scrollback_lines = 10000 -- 기본값은 좀 적어서 10000줄로 늘림

-- 커서 스타일 (깜빡이는 바 형태)
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 800

-- 탭 바 위치 및 스타일
config.use_fancy_tab_bar = false -- false로 해야 고전적인 탭 스타일(아래 colors 적용)이 잘 먹힘
config.window_background_opacity = 0.90
config.macos_window_background_blur = 50

config.mouse_bindings = {
    -- 드래그해서 선택을 마치면(Left Up) -> 자동으로 클립보드에 복사
    {
        event = {Up = {streak = 1, button = 'Left'}},
        mods = 'NONE',
        action = act.CompleteSelection 'Clipboard'
    }, -- 마우스 우클릭(Right Down) -> 클립보드 내용 붙여넣기
    {
        event = {Down = {streak = 1, button = 'Right'}},
        mods = 'NONE',
        action = act.PasteFrom 'Clipboard'
    }, -- Linux는 휠클릭
    {
        event = {Down = {streak = 1, button = 'Middle'}},
        mods = 'NONE',
        action = act.PasteFrom 'Clipboard'
    }
}

config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- 우측 상태바 (Right Status Bar) 설정
-- 탭 바 오른쪽 빈 공간에 [워크스페이스 이름 | 날짜]을 표시

wezterm.on('update-right-status', function(window, pane)
    local date = wezterm.strftime '%Y-%m-%d '
    local workspace = window:active_workspace() -- 현재 워크스페이스 이름 가져오기
    local key_table = window:active_key_table()
    if key_table then key_table = 'TABLE: ' .. key_table end

    -- 도움말 안내 문구
    local help_text = (CMD == "SUPER" and "⌘" or "Ctrl") .. "+/ Help "

    window:set_right_status(wezterm.format({
        -- 1. 도움말 (보라색)
        {Foreground = {Color = '#bb9af7'}}, {Text = help_text .. ' | '},

        -- 2. 워크스페이스 (녹색 - 눈에 잘 띔)
        {Foreground = {Color = '#9ece6a'}}, {Text = '󱂬 ' .. workspace}, -- 워크스페이스 아이콘 추가

        -- 3. 키 테이블 (활성화 시에만 파란색으로 표시)
        {Foreground = {Color = '#7aa2f7'}},
        {Text = key_table and (' | ' .. key_table) or ''},

        -- 4. 날짜 (연한 파란색)
        {Foreground = {Color = '#c0caf5'}}, {Text = ' | ' .. date .. '  '}
    }))
end)

-- ---------------------------------------------------------
-- [키바인딩] 단축키 설정
-- ---------------------------------------------------------

config.keys = {
    -- 커맨드 팔레트 (VSCode 처럼 명령 검색) - Ctrl+Shift+P
    {key = 'p', mods = CMD .. '|SHIFT', action = act.ActivateCommandPalette},
    -- 복사: Win(Ctrl+Shift+C), Mac(Cmd+C) -> 맥은 보통 Shift 없이 씀
    {key = 'c', mods = CMD .. '|SHIFT', action = act.CopyTo 'Clipboard'},
    {key = 'v', mods = CMD .. '|SHIFT', action = act.PasteFrom 'Clipboard'},

    -- 검색 모드: 로그 찾을 때 필수 (Ctrl+Shift+F)
    {
        key = 'f',
        mods = CMD .. '|SHIFT',
        action = act.Search 'CurrentSelectionOrEmptyString'
    }, -- 폰트 크기 조절
    {key = '+', mods = CMD, action = act.IncreaseFontSize},
    {key = '-', mods = CMD, action = act.DecreaseFontSize},
    {key = '0', mods = CMD, action = act.ResetFontSize},

    -- 2. 화면 분할 (Ctrl + Opt + -/\)
    {
        key = '-',
        mods = 'CTRL|' .. OPT,
        action = act.SplitVertical {domain = 'CurrentPaneDomain'}
    }, {
        key = '\\',
        mods = 'CTRL|' .. OPT,
        action = act.SplitHorizontal {domain = 'CurrentPaneDomain'}
    }, -- 3. 창(Pane) 이동 (Option + 방향키)
    {key = 'LeftArrow', mods = OPT, action = act.ActivatePaneDirection 'Left'},
    {key = 'RightArrow', mods = OPT, action = act.ActivatePaneDirection 'Right'},
    {key = 'UpArrow', mods = OPT, action = act.ActivatePaneDirection 'Up'},
    {key = 'DownArrow', mods = OPT, action = act.ActivatePaneDirection 'Down'},

    -- 4. 창(Pane) 닫기 (Win: Ctrl+w, Mac: Cmd+w)
    {key = 'w', mods = CMD, action = act.CloseCurrentPane {confirm = true}},

    -- 5. 탭(Tab) 관리 (Win: Ctrl+t, Mac: Cmd+t)
    {key = 't', mods = CMD, action = act.SpawnTab 'CurrentPaneDomain'},
    -- 탭 이동
    {key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1)}, -- 탭 이동은 보통 Ctrl+Tab이 국룰이라 고정
    {key = 'Tab', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1)},

    -- 6. 탭 번호로 바로 이동 (Win: Ctrl+1~9, Mac: Cmd+1~9)
    {key = '1', mods = CMD, action = act.ActivateTab(0)},
    {key = '2', mods = CMD, action = act.ActivateTab(1)},
    {key = '3', mods = CMD, action = act.ActivateTab(2)},
    {key = '4', mods = CMD, action = act.ActivateTab(3)},
    {key = '5', mods = CMD, action = act.ActivateTab(4)},
    {key = '6', mods = CMD, action = act.ActivateTab(5)},
    {key = '7', mods = CMD, action = act.ActivateTab(6)},
    {key = '8', mods = CMD, action = act.ActivateTab(7)},
    {key = '9', mods = CMD, action = act.ActivateTab(-1)}, -- 마지막 탭
    -- 7. Pane 크기 조절 (Option + Shift + 방향키)
    {
        key = 'LeftArrow',
        mods = OPT .. '|SHIFT',
        action = act.AdjustPaneSize {'Left', 3}
    }, {
        key = 'RightArrow',
        mods = OPT .. '|SHIFT',
        action = act.AdjustPaneSize {'Right', 3}
    }, {
        key = 'UpArrow',
        mods = OPT .. '|SHIFT',
        action = act.AdjustPaneSize {'Up', 3}
    }, {
        key = 'DownArrow',
        mods = OPT .. '|SHIFT',
        action = act.AdjustPaneSize {'Down', 3}
    }, -- 리사이즈 모드 진입 (Alt + R / Opt + R)
    {
        key = 'r',
        mods = OPT,
        action = act.ActivateKeyTable {name = 'resize_pane', one_shot = false}
    }, -- 8. Pane 줌 토글 (Ctrl + Option + Z)
    {key = 'z', mods = 'CTRL|' .. OPT, action = act.TogglePaneZoomState},

    -- 9. 현재 Pane을 새 탭으로 분리 (Ctrl + Option + T)
    {
        key = 't',
        mods = 'CTRL|' .. OPT,
        action = wezterm.action_callback(function(win, pane)
            pane:move_to_new_tab()
        end)
    }, -- 워크스페이스 만들기
    {
        key = 's',
        mods = CMD .. '|SHIFT',
        action = act.ShowLauncherArgs {flags = 'WORKSPACES'}
    }, {
        key = 'r',
        mods = CMD .. '|SHIFT',
        action = act.PromptInputLine {
            description = '(WezTerm) set workspace name:',
            action = wezterm.action_callback(
                function(window, pane, line)
                    if line then
                        wezterm.mux.rename_workspace(wezterm.mux
                                                         .get_active_workspace(),
                                                     line)
                    end
                end)
        }
    }, {
        key = 'L',
        mods = CMD .. '|SHIFT',
        action = act.ShowLauncherArgs {flags = 'FUZZY|LAUNCH_MENU_ITEMS'}
    }, -- ---------------------------------------------------------
    -- [단축키 도움말 패널] 추가
    -- ---------------------------------------------------------
    {
        key = '/',
        mods = CMD, -- Win: Ctrl+/, Mac: Cmd+/
        action = act.InputSelector {
            title = "🚀 My Shortcut Guide",
            choices = {
                -- 1. Pane (창) 관련
                {label = "Pane: 가로 분할 (Ctrl+" .. OPT .. "+\\)"},
                {label = "Pane: 세로 분할 (Ctrl+" .. OPT .. "-)"},
                {label = "Pane: 이동 (" .. OPT .. " + 방향키)"},
                {
                    label = "Pane: 크기 조절 (Shift+" .. OPT ..
                        " + 방향키)"
                },
                {label = "Pane: 리사이즈 모드 진입 (" .. OPT .. "+R)"},
                {label = "Pane: 줌(확대) 토글 (Ctrl+" .. OPT .. "+Z)"},
                {
                    label = "Pane: 현재 창을 새 탭으로 분리 (Ctrl+" ..
                        OPT .. "+T)"
                }, {label = "Pane: 닫기 (" .. CMD .. "+W)"}, {
                    label = "Pane: 다음 창으로 포커스 (" .. CMD ..
                        "+[ 또는 ]) - 내장"
                }, -- 2. Tab / Workspace 관련
                {label = "Tab: 새 탭 열기 (" .. CMD .. "+T)"},
                {
                    label = "Tab: 다음/이전 탭 이동 (Ctrl+Tab / Ctrl+Shift+Tab)"
                }, {label = "Tab: 번호로 이동 (" .. CMD .. "+1~9)"},
                {label = "Workspace: 이름 바꾸기 (" .. CMD .. "+Shift+R)"},
                {label = "Workspace: 목록 보기 (" .. CMD .. "+Shift+S)"},

                -- 3. 검색 및 선택 (Search & Selection)
                {label = "Search: 로그 검색 (" .. CMD .. "+Shift+F)"},
                {label = "Copy: 복사 (" .. CMD .. "+Shift+C)"},
                {label = "Paste: 붙여넣기 (" .. CMD .. "+Shift+V)"},

                -- 4. 시스템 및 유틸리티 (WezTerm 내장 핵심)
                {
                    label = "System: 명령 팔레트 실행 (" .. CMD ..
                        "+Shift+P)"
                }, {label = "View: 전체화면 토글 (" .. OPT .. "+Enter)"},
                {label = "View: 폰트 크기 조절 (" .. CMD .. " + +/-/0)"},
                {label = "View: 화면 스크롤 (Shift+PageUp/Down)"}, {
                    label = "Window: 창 숨기기 (" .. CMD ..
                        "+H) / 최소화 (" .. CMD .. "+M)"
                }, {label = "Window: WezTerm 종료 (" .. CMD .. "+Q)"},

                -- 5. 모드 조작
                {label = "Mode: 리사이즈/검색 모드 탈출 (ESC)"},
                {label = "Search Mode: 결과 이동 (Enter / Shift+Enter)"},
                {label = "Search Mode: 검색모드 토글 (Ctrl+R)"}, -- 쉘
                {
                    label = "System: 쉘 선택 메뉴 열기 (" .. CMD ..
                        "+Shift+L)"
                }
            },
            action = wezterm.action_callback(
                function(window, pane, id, label) end)
        }
    }
}

-- ---------------------------------------------------------
-- [검색 모드] 프리징 방지를 위한 전용 키바인딩
-- ---------------------------------------------------------
-- 검색 모드에서는 별도의 key_table이 활성화됨.
-- 기본 키맵이 터미널 동작과 충돌하여 프리징이 발생할 수 있으므로
-- 검색에 필요한 키만 명시적으로 매핑한다.

config.key_tables = {
    resize_pane = {
        {key = 'LeftArrow', action = act.AdjustPaneSize {'Left', 1}},
        {key = 'RightArrow', action = act.AdjustPaneSize {'Right', 1}},
        {key = 'UpArrow', action = act.AdjustPaneSize {'Up', 1}},
        {key = 'DownArrow', action = act.AdjustPaneSize {'Down', 1}},
        {key = 'Escape', action = 'PopKeyTable'},
        {key = 'Enter', action = 'PopKeyTable'}
    },
    search_mode = {
        -- Enter: 선택된 검색어 복사 모드로 진입 (혹은 뷰포트 이동)
        {key = 'Enter', mods = 'NONE', action = act.CopyMode 'PriorMatch'},
        {key = 'Enter', mods = 'SHIFT', action = act.CopyMode 'NextMatch'},

        -- Ctrl+n/p: 검색 결과 위아래 이동 (Emacs 스타일)
        {key = 'n', mods = 'CTRL', action = act.CopyMode 'NextMatch'},
        {key = 'p', mods = 'CTRL', action = act.CopyMode 'PriorMatch'},

        -- 위/아래 화살표: 검색 결과 이동
        {key = 'UpArrow', mods = 'NONE', action = act.CopyMode 'PriorMatch'},
        {key = 'DownArrow', mods = 'NONE', action = act.CopyMode 'NextMatch'},

        -- Ctrl+r: 정규식 검색 모드 토글
        {key = 'r', mods = 'CTRL', action = act.CopyMode 'CycleMatchType'},

        -- 검색창 지우기 또는 검색어 입력 (입력 모드는 자동으로 활성화되지만 명시적 바인딩 가능)
        {key = 'u', mods = 'CTRL', action = act.CopyMode 'ClearPattern'},

        -- ESC: 검색 모드 종료
        {key = 'Escape', mods = 'NONE', action = act.CopyMode 'Close'}
    }
}

-- ---------------------------------------------------------
-- [탭 바 색상 상세 설정]
-- ---------------------------------------------------------
config.window_frame = {
    font = wezterm.font {family = 'JetBrains Mono', weight = 'Bold'},
    font_size = 11.0,
    active_titlebar_bg = '#1e1e2e', -- 탭바 배경색 (더 어둡게)
    inactive_titlebar_bg = '#1e1e2e'
}

config.colors = {
    tab_bar = {
        background = '#1e1e2e',

        -- 활성화된 탭 스타일
        active_tab = {
            bg_color = '#7aa2f7',
            fg_color = '#1e1e2e',
            intensity = 'Bold'
        },
        inactive_tab = {bg_color = '#292e42', fg_color = '#545c7e'},
        inactive_tab_hover = {bg_color = '#3b4261', fg_color = '#c0caf5'}
    }
}

-- ---------------------------------------------------------
-- [탭 타이틀] 현재 폴더명 표시 (Mac/Windows/Linux 호환)
-- ---------------------------------------------------------

--- current_working_dir에서 마지막 폴더명만 안전하게 추출
local function get_current_working_dir(tab)
    -- 1) pane에서 cwd 가져오기
    local cwd_uri = tab.active_pane and tab.active_pane.current_working_dir
    if not cwd_uri then return 'Terminal' end

    -- 2) URL 객체 → file_path 문자열 추출
    --    wezterm은 cwd를 URL userdata로 반환함 (e.g. "file:///Users/foo/project")
    --    .file_path 속성으로 디코딩된 경로를 얻을 수 있음
    local path = ''
    if type(cwd_uri) == 'userdata' or type(cwd_uri) == 'table' then
        path = cwd_uri.file_path or ''
    elseif type(cwd_uri) == 'string' then
        -- 혹시 문자열로 오는 경우: "file:///home/user/project" 형태
        path = cwd_uri:match('file://[^/]*(/.+)') or cwd_uri
    end

    -- 3) Windows 경로 정규화: 백슬래시 → 슬래시
    path = path:gsub('\\', '/')

    -- 4) 끝의 슬래시 제거 (e.g. "/home/user/project/" → "/home/user/project")
    path = path:gsub('/$', '')

    -- 5) 마지막 슬래시 이후 부분 = 폴더명
    local folder = path:match('([^/]+)$')

    -- 6) 홈 디렉토리인 경우 (~) 또는 빈 경우 처리
    if not folder or folder == '' then return '~' end

    -- 홈 폴더명과 비교하여 ~ 표시
    if folder == home_folder and path == home then return '~' end

    return folder
end

wezterm.on('format-tab-title',
           function(tab, tabs, panes, config, hover, max_width)
    local title = get_current_working_dir(tab)

    -- Tokyo Night 테마 기준 색상
    local bg = '#1e1e2e'
    local fg = '#545c7e'

    if tab.is_active then
        bg = '#7aa2f7'
        fg = '#1e1e2e'
    elseif hover then
        bg = '#3b4261'
        fg = '#c0caf5'
    end

    return {
        {Background = {Color = bg}}, {Foreground = {Color = fg}},
        {Text = '  ' .. title .. '  '}
    }
end)

return config

classdef ControlEngineeringLab < matlab.apps.AppBase

    % Properti Utama UI
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        MainGrid                matlab.ui.container.GridLayout
        
        % Panels Halaman
        LoginPanel              matlab.ui.container.Panel
        MenuPanel               matlab.ui.container.Panel
        LaplacePanel            matlab.ui.container.Panel
        RootLocusPanel          matlab.ui.container.Panel
        PIDPanel                matlab.ui.container.Panel
        BlackBoxPanel           matlab.ui.container.Panel
        ProfilePanel            matlab.ui.container.Panel
       
        % Komponen Login
        UserEdit                matlab.ui.control.EditField
        PassEdit                matlab.ui.control.EditField
        ShowPassCheck           matlab.ui.control.CheckBox
        
        % Komponen Laplace Calculator
        LapModeDrop             matlab.ui.control.DropDown
        LapLabel1               matlab.ui.control.Label
        LapEdit1                matlab.ui.control.EditField
        LapLabel2               matlab.ui.control.Label
        LapEdit2                matlab.ui.control.EditField
        LapHintLabel            matlab.ui.control.Label
        LapResultArea           matlab.ui.control.TextArea
        LapStepsArea            matlab.ui.control.TextArea
        
        % Komponen Root Locus
        RLNumEdit               matlab.ui.control.EditField
        RLDenEdit               matlab.ui.control.EditField
        RLKMaxEdit              matlab.ui.control.NumericEditField
        RLKSlider               matlab.ui.control.Slider
        RLKEdit                 matlab.ui.control.EditField
        RLStatusLabel           matlab.ui.control.Label
        RLAxes                  matlab.ui.control.UIAxes
        RLStepAxes              matlab.ui.control.UIAxes
        RLInfoArea              matlab.ui.control.TextArea
        
        % Komponen PID Control Panel
        PIDNumEdit              matlab.ui.control.EditField
        PIDDenEdit              matlab.ui.control.EditField
        PIDTsimEdit             matlab.ui.control.NumericEditField
        PIDConfigDrop           matlab.ui.control.DropDown
        PIDPCheck               matlab.ui.control.CheckBox
        PIDICheck               matlab.ui.control.CheckBox
        PIDDCheck               matlab.ui.control.CheckBox
        PIDKpSlider             matlab.ui.control.Slider
        PIDKpEdit               matlab.ui.control.NumericEditField
        PIDKiSlider             matlab.ui.control.Slider
        PIDKiEdit               matlab.ui.control.NumericEditField
        PIDKdSlider             matlab.ui.control.Slider
        PIDKdEdit               matlab.ui.control.NumericEditField
        PIDDistCheck            matlab.ui.control.CheckBox
        PIDDistMagEdit          matlab.ui.control.NumericEditField
        PIDDistTimeEdit         matlab.ui.control.NumericEditField
        PIDStepAxes             matlab.ui.control.UIAxes
        PIDDistAxes             matlab.ui.control.UIAxes
        PIDMetricTable          matlab.ui.control.Table
        PIDSummaryArea          matlab.ui.control.TextArea
        PIDLogTable             matlab.ui.control.Table
        
        % Komponen Black Box (Bonus)
        BBInfoLabel             matlab.ui.control.Label
        BBAxes                  matlab.ui.control.UIAxes
        BBModelTable            matlab.ui.control.Table
        BBStepsArea             matlab.ui.control.TextArea
        
        % Komponen Profile
        ProfImage               matlab.ui.control.Image
        ProfNameEdit            matlab.ui.control.EditField
        ProfNIMEdit             matlab.ui.control.EditField
        ProfProdiEdit           matlab.ui.control.EditField
        ProfAngkatanEdit        matlab.ui.control.EditField
        ProfNoteArea            matlab.ui.control.TextArea
    end

    properties (Access = private)
        % Kredensial Login Default 
        ValidUser = 'ezra';
        ValidPass = '612024008';
        ActualPassword = '';

        % Data Internal Root Locus
        RL_num = 1;
        RL_den = [1 3 2 0];
        
        % Data Internal Black Box
        BB_t = [];
        BB_u = [];
        BB_y = [];
        
        % Counter Log Percobaan PID
        PID_ExpCount = 0;
    end

    methods (Access = private)

        %% ================= NAVIGASI HALAMAN =================
        function showPage(app, targetPanel)
            allPanels = [app.LoginPanel, app.MenuPanel, app.LaplacePanel, ...
                         app.RootLocusPanel, app.PIDPanel, app.BlackBoxPanel, app.ProfilePanel];
            for k = 1:numel(allPanels)
                allPanels(k).Visible = 'off';
            end
            targetPanel.Visible = 'on';
        end

        function bar = createTopBar(app, parentGrid, pageTitle)
            bar = uipanel(parentGrid, 'BackgroundColor', [0.07 0.14 0.23], 'BorderType', 'none');
            bar.Layout.Row = 1;
            bar.Layout.Column = [1 2];
            
            g = uigridlayout(bar, [1 4]);
            g.ColumnWidth = {'1x', 140, 90, 80};
            g.Padding = [15 6 15 6];
            
            lbl = uilabel(g, 'Text', ['Control Engineering Lab  |  ' pageTitle], ...
                'FontColor', [1 1 1], 'FontSize', 15, 'FontWeight', 'bold');
            lbl.Layout.Column = 1;
            
            btnMenu = uibutton(g, 'Text', 'Menu Utama', ...
                'BackgroundColor', [0.09 0.49 0.52], 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~,~) app.showPage(app.MenuPanel));
            btnMenu.Layout.Column = 2;
            
            btnLogout = uibutton(g, 'Text', 'Logout', ...
                'BackgroundColor', [0.85 0.55 0.12], 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~,~) app.doLogout());
            btnLogout.Layout.Column = 3;
            
            btnExit = uibutton(g, 'Text', 'Exit', ...
                'BackgroundColor', [0.78 0.22 0.22], 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~,~) delete(app.UIFigure));
            btnExit.Layout.Column = 4;
        end

        %% ================= LOGIKA LOGIN =================
        function doLogin(app)
            u = strtrim(app.UserEdit.Value);
            p = app.ActualPassword;
            if strcmp(u, app.ValidUser) && strcmp(p, app.ValidPass)
                app.showPage(app.MenuPanel);
            else
                uialert(app.UIFigure, 'Username atau Password salah! (Default: admin / 12345)', ...
                    'Login Gagal', 'Icon', 'error');
            end
        end

        function onPasswordChanging(app, event)
            newStr = char(event.Value);
            if app.ShowPassCheck.Value
                app.ActualPassword = newStr;
            else
                bullet = char(8226);
                n = length(newStr);
                prefixLen = 0;
                while prefixLen < n && newStr(prefixLen + 1) == bullet
                    prefixLen = prefixLen + 1;
                end
                suffixLen = 0;
                while (prefixLen + suffixLen) < n && newStr(n - suffixLen) == bullet
                    suffixLen = suffixLen + 1;
                end
                inserted = newStr(prefixLen + 1 : n - suffixLen);
                oldLen = length(app.ActualPassword);
                keepPrefix = min(prefixLen, oldLen);
                keepSuffixStart = max(keepPrefix + 1, oldLen - suffixLen + 1);
                app.ActualPassword = [app.ActualPassword(1:keepPrefix), inserted, app.ActualPassword(keepSuffixStart:oldLen)];
                app.PassEdit.Value = repmat(bullet, 1, length(app.ActualPassword));
            end
        end

        function togglePassword(app)
            if app.ShowPassCheck.Value
                app.PassEdit.Value = app.ActualPassword;
            else
                app.PassEdit.Value = repmat(char(8226), 1, length(app.ActualPassword));
            end
        end

        function doLogout(app)
            app.UserEdit.Value = '';
            app.PassEdit.Value = '';
            app.ActualPassword = '';
            app.ShowPassCheck.Value = false;
            app.showPage(app.LoginPanel);
        end

        %% ================= LOGIKA LAPLACE CALCULATOR (PURE MATLAB) =================
        function onLaplaceModeChanged(app)
            mode = app.LapModeDrop.Value;
            switch mode
                case 'Transformasi Laplace'
                    app.LapLabel1.Text = 'f(t) =';
                    app.LapEdit1.Value = 'exp(-2*t)*sin(3*t)';
                    app.LapLabel2.Visible = 'off';
                    app.LapEdit2.Visible = 'off';
                    app.LapHintLabel.Text = 'Gunakan variabel t. Contoh: 5*t^2 + 3, exp(-2*t)*sin(3*t), t*exp(-t), cos(4*t), heaviside(t-1)';
                case 'Invers Laplace'
                    app.LapLabel1.Text = 'F(s) =';
                    app.LapEdit1.Value = '(s+3)/(s^2+3*s+2)';
                    app.LapLabel2.Visible = 'off';
                    app.LapEdit2.Visible = 'off';
                    app.LapHintLabel.Text = 'Gunakan variabel s. Contoh: (s+3)/(s^2+3*s+2), 1/(s^2+4), (s+1)/(s*(s+2)^2), 5/(s^2+2*s+5)';
                case 'Pecahan Parsial'
                    app.LapLabel1.Text = 'Numerator N(s) (koefisien, pangkat s menurun):';
                    app.LapEdit1.Value = '[1 3]';
                    app.LapLabel2.Visible = 'on';
                    app.LapEdit2.Visible = 'on';
                    app.LapEdit2.Value = '[1 3 2]';
                    app.LapHintLabel.Text = 'Masukkan koefisien polinom, contoh N = [1 3] dan D = [1 3 2] untuk (s+3)/(s^2+3s+2). Pole kembar dan pole kompleks didukung.';
            end
            app.LapResultArea.Value = {''};
            app.LapStepsArea.Value = {''};
        end

        function resetLaplace(app)
            app.LapEdit1.Value = '';
            app.LapEdit2.Value = '';
            app.LapResultArea.Value = {''};
            app.LapStepsArea.Value = {''};
        end

        function computeLaplace(app)
            mode = app.LapModeDrop.Value;
            try
                if strcmp(mode, 'Transformasi Laplace')
                    exprStr = strtrim(app.LapEdit1.Value);
                    if isempty(exprStr)
                        error('Input f(t) tidak boleh kosong.');
                    end
                    
                    [Fs_str, termNotes, F_eval_fn] = app.forwardLaplaceEngine(exprStr);
                    app.LapResultArea.Value = {['F(s) = ' Fs_str]};
                    
                    % Verifikasi numerik langsung dari integral definisi pada s = 10
                    s_val = 10;
                    heaviside = @(x) double(x >= 0); %#ok<NASGU>
                    f_num = eval(['@(t) ' vectorize(exprStr)]);
                    val_int = integral(@(tau) f_num(tau) .* exp(-s_val .* tau), 0, Inf, 'RelTol', 1e-8);
                    val_ana = F_eval_fn(s_val);
                    err_val = abs(val_int - val_ana);
                    
                    verifLine = sprintf(['VERIFIKASI NUMERIK (langsung dari integral definisi pada s = %g):\n' ...
                        '  Nilai integral = %.7g,  F(s) = %.7g,  selisih = %.3e'], ...
                        s_val, val_int, val_ana, err_val);
                    
                    steps = [
                        {'LANGKAH 1 - Definisi transformasi Laplace sepihak:'; ...
                         '  F(s) = integral dari 0 sampai tak hingga: f(t) * exp(-s*t) dt'; ''; ...
                         'LANGKAH 2 - Fungsi masukan:'; ...
                         ['  f(t) = ' exprStr]; ''; ...
                         'LANGKAH 3 - Cocokkan tiap suku dengan tabel & sifat pergeseran frekuensi:'}
                        termNotes'
                        {''; 'LANGKAH 4 - Jumlahkan dan sederhanakan bentuk akhir:'; ...
                         ['  F(s) = ' Fs_str]; ''; verifLine}
                    ];
                    app.LapStepsArea.Value = steps;
                    
                elseif strcmp(mode, 'Invers Laplace')
                    exprStr = strtrim(app.LapEdit1.Value);
                    if isempty(exprStr)
                        error('Input F(s) tidak boleh kosong.');
                    end
                    
                    [ft_str, pf_str, step3Lines, F_orig_fn, f_num_fn] = app.inverseLaplaceEngine(exprStr);
                    app.LapResultArea.Value = {['f(t) = ' ft_str '   (untuk t >= 0)']};
                    
                    % Verifikasi balik dengan menghitung integral Laplace dari f(t) pada s = 6
                    s_test = 6;
                    val_F = F_orig_fn(s_test);
                    val_L = integral(@(tau) f_num_fn(tau) .* exp(-s_test .* tau), 0, Inf, 'RelTol', 1e-8);
                    diff_val = abs(val_F - val_L);
                    if diff_val < 1e-5
                        statusCheck = 'COCOK';
                    else
                        statusCheck = 'PERIKSA KONVERGENSI';
                    end
                    
                    steps = [
                        {'LANGKAH 1 - Fungsi masukan:'; ...
                         ['  F(s) = ' exprStr]; ''; ...
                         'LANGKAH 2 - Uraikan menjadi pecahan parsial (bentuk standar tabel):'; ...
                         ['  F(s) = ' pf_str]; ''; ...
                         'LANGKAH 3 - Invers tiap suku memakai tabel & sifat linearitas:'}
                        step3Lines'
                        {''; 'LANGKAH 4 - Jumlahkan hasil (berlaku untuk t >= 0):'; ...
                         ['  f(t) = ' ft_str]; ''; ...
                         sprintf('VERIFIKASI: Uji integral L{f(t)} pada s = %g -> F(%g) = %.6g, L{f(t)} = %.6g (selisih = %.2e) -> %s', ...
                         s_test, s_test, val_F, val_L, diff_val, statusCheck)}
                    ];
                    app.LapStepsArea.Value = steps;
                    
                else % Pecahan Parsial (Numerik dengan residue)
                    num = str2num(app.LapEdit1.Value); %#ok<ST2NM>
                    den = str2num(app.LapEdit2.Value); %#ok<ST2NM>
                    if isempty(num) || isempty(den) || ~isnumeric(num) || ~isnumeric(den) || all(den == 0)
                        error('Koefisien Numerator dan Denominator harus berupa vektor numerik valid.');
                    end
                    
                    [Fs_str, ft_str, detailRes, p, r, k] = app.partialFractionHelper(num, den);
                    
                    app.LapResultArea.Value = {
                        ['F(s) = ' Fs_str]
                        ''
                        ['f(t) = ' ft_str '   (t >= 0)']
                    };
                    
                    % Verifikasi pada titik kompleks s0 = 0.37 + 1.21i
                    s0 = 0.37 + 1.21i;
                    val_orig = polyval(num, s0) / polyval(den, s0);
                    val_pf = 0;
                    idx = 1;
                    nPoles = length(p);
                    while idx <= nPoles
                        mult = 1;
                        while (idx + mult <= nPoles) && (abs(p(idx + mult) - p(idx)) < 1e-5)
                            mult = mult + 1;
                        end
                        for m = 1:mult
                            val_pf = val_pf + r(idx + m - 1) / ((s0 - p(idx))^m);
                        end
                        idx = idx + mult;
                    end
                    if ~isempty(k)
                        val_pf = val_pf + polyval(k, s0);
                    end
                    err_pf = abs(val_orig - val_pf);
                    
                    if length(num) < length(den)
                        step2Txt = 'LANGKAH 2 - N(s) lebih rendah orde dari D(s) (proper): langsung uraikan.';
                    else
                        step2Txt = 'LANGKAH 2 - N(s) >= orde D(s) (improper): lakukan pembagian polinom terlebih dahulu.';
                    end
                    
                    poleListStr = strjoin(arrayfun(@(z) sprintf('%.4g%+.4gi', real(z), imag(z)), p, 'UniformOutput', false), ', ');
                    
                    steps = [
                        {'LANGKAH 1 - Faktorisasi penyebut (cari pole):'; ...
                         ['  D(s) = ' app.polyToString(den)]; ...
                         ['  pole = ' poleListStr]; ''; step2Txt; ''; ...
                         'LANGKAH 3 - Hitung residu tiap pole (metode Heaviside / residue()):'}
                        detailRes'
                        {''; 'LANGKAH 4 - Invers Laplace tiap suku: L^-1{1/(s-p)^m} = t^(m-1)/(m-1)! * exp(p*t)'; ...
                         '  (Pasangan pole kompleks konjugat digabung: 2|r| e^(sigma t) cos(w t + sudut(r)))'; ''; ...
                         sprintf('VERIFIKASI pada s0 = 0.37 + 1.21i:\n  N(s0)/D(s0) = %.4f%+.4fi ; jumlah pecahan parsial = %.4f%+.4fi ; selisih = %.2e', ...
                         real(val_orig), imag(val_orig), real(val_pf), imag(val_pf), err_pf)}
                    ];
                    app.LapStepsArea.Value = steps;
                end
            catch ME
                uialert(app.UIFigure, ['Input tidak valid atau format fungsi belum dikenali: ' ME.message], ...
                    'Error Perhitungan', 'Icon', 'error');
            end
        end

        function [Fs_str, termNotes, F_eval_fn] = forwardLaplaceEngine(~, exprStr)
            % Memecah ekspresi f(t) menjadi suku-suku penjumlahan tingkat atas
            sClean = regexprep(exprStr, '\s+', '');
            terms = {};
            depth = 0;
            startIdx = 1;
            for i = 1:length(sClean)
                ch = sClean(i);
                if ch == '('
                    depth = depth + 1;
                elseif ch == ')'
                    depth = depth - 1;
                elseif (ch == '+' || ch == '-') && depth == 0 && i > 1
                    prevCh = sClean(i-1);
                    if ~ismember(prevCh, ['*', '/', '^', 'e', 'E'])
                        terms{end+1} = sClean(startIdx:i-1); %#ok<AGROW>
                        startIdx = i;
                    end
                end
            end
            terms{end+1} = sClean(startIdx:end);
            if depth ~= 0
                error('Jumlah tanda kurung buka dan tutup tidak seimbang.');
            end
            
            outParts = {};
            termNotes = {};
            evalParts = {};
            
            for k = 1:length(terms)
                tk = terms{k};
                if isempty(tk), continue; end
                
                % Pisahkan faktor perkalian tingkat atas
                factors = {};
                d2 = 0; st2 = 1;
                for j = 1:length(tk)
                    c2 = tk(j);
                    if c2 == '(', d2 = d2 + 1;
                    elseif c2 == ')', d2 = d2 - 1;
                    elseif c2 == '*' && d2 == 0
                        factors{end+1} = tk(st2:j-1); %#ok<AGROW>
                        st2 = j + 1;
                    end
                end
                factors{end+1} = tk(st2:end);
                
                gain = 1;
                nPow = 0;
                aExp = 0;
                trigType = '';
                wTrig = 0;
                delayTau = NaN;
                
                for fIdx = 1:length(factors)
                    fac = factors{fIdx};
                    if strcmp(fac, '-t')
                        gain = -gain; nPow = nPow + 1;
                    elseif strcmp(fac, '+t') || strcmp(fac, 't')
                        nPow = nPow + 1;
                    elseif startsWith(fac, '-exp(') || startsWith(fac, '-sin(') || startsWith(fac, '-cos(') || ...
                           startsWith(fac, '-sinh(') || startsWith(fac, '-cosh(') || startsWith(fac, '-heaviside(')
                        gain = -gain;
                        fac = fac(2:end);
                    elseif startsWith(fac, '+')
                        fac = fac(2:end);
                    end
                    
                    valNum = str2double(fac);
                    if ~isnan(valNum)
                        gain = gain * valNum;
                    elseif strcmp(fac, 't')
                        % sudah ditangani di atas
                    elseif ~isempty(regexp(fac, '^t\^(\d+)$', 'tokens'))
                        tok = regexp(fac, '^t\^(\d+)$', 'tokens');
                        nPow = nPow + str2double(tok{1}{1});
                    elseif ~isempty(regexp(fac, '^exp\((.+)\)$', 'tokens'))
                        tok = regexp(fac, '^exp\((.+)\)$', 'tokens');
                        arg = tok{1}{1};
                        if strcmp(arg, 't'), aExp = aExp + 1;
                        elseif strcmp(arg, '-t'), aExp = aExp - 1;
                        else
                            coefA = str2double(regexprep(arg, '\*?t$', ''));
                            if isnan(coefA), error(['Argumen exp tidak didukung: ' arg]); end
                            aExp = aExp + coefA;
                        end
                    elseif ~isempty(regexp(fac, '^(sin|cos|sinh|cosh)\((.+)\)$', 'tokens'))
                        tok = regexp(fac, '^(sin|cos|sinh|cosh)\((.+)\)$', 'tokens');
                        trigType = tok{1}{1};
                        arg = tok{1}{2};
                        if strcmp(arg, 't'), wTrig = 1;
                        else
                            wTrig = str2double(regexprep(arg, '\*?t$', ''));
                            if isnan(wTrig), error(['Argumen fungsi trigonometri tidak didukung: ' arg]); end
                        end
                    elseif ~isempty(regexp(fac, '^heaviside\((.+)\)$', 'tokens'))
                        tok = regexp(fac, '^heaviside\((.+)\)$', 'tokens');
                        arg = tok{1}{1};
                        if strcmp(arg, 't')
                            delayTau = 0;
                        elseif ~isempty(regexp(arg, '^t([+-]\d+\.?\d*)$', 'tokens'))
                            tokD = regexp(arg, '^t([+-]\d+\.?\d*)$', 'tokens');
                            delayTau = -str2double(tokD{1}{1});
                            if delayTau < 0
                                error('Pergeseran waktu heaviside(t - tau) harus memiliki tau >= 0.');
                            end
                        else
                            error(['Argumen heaviside tidak didukung: ' arg]);
                        end
                    else
                        error(['Suku fungsi tidak dikenali: ' fac]);
                    end
                end
                
                % Bangun bentuk Laplace F_k(s)
                if aExp == 0
                    sShiftStr = 's';
                    sShiftEval = 's';
                elseif aExp > 0
                    sShiftStr = sprintf('(s - %g)', aExp);
                    sShiftEval = sprintf('(s - %g)', aExp);
                else
                    sShiftStr = sprintf('(s + %g)', abs(aExp));
                    sShiftEval = sprintf('(s + %g)', abs(aExp));
                end
                
                if ~isnan(delayTau)
                    if nPow ~= 0 || aExp ~= 0 || ~isempty(trigType)
                        error('Untuk fungsi step tertunda, gunakan format c*heaviside(t - tau).');
                    end
                    if delayTau == 0
                        fStr = sprintf('%g/s', gain);
                        eStr = sprintf('(%g./s)', gain);
                    else
                        fStr = sprintf('%g*exp(-%g*s)/s', gain, delayTau);
                        eStr = sprintf('(%g.*exp(-%g.*s)./s)', gain, delayTau);
                    end
                elseif isempty(trigType)
                    numVal = gain * factorial(nPow);
                    if nPow == 0
                        fStr = sprintf('%g/%s', numVal, sShiftStr);
                        eStr = sprintf('(%g./%s)', numVal, sShiftEval);
                    else
                        fStr = sprintf('%g/%s^%d', numVal, sShiftStr, nPow + 1);
                        eStr = sprintf('(%g./(%s.^%d))', numVal, sShiftEval, nPow + 1);
                    end
                else
                    if nPow ~= 0
                        error('Perkalian t^n dengan sin/cos belum didukung pada parser sederhana ini.');
                    end
                    if aExp == 0
                        quadStr = sprintf('(s^2 + %g)', wTrig^2);
                        quadEval = sprintf('(s.^2 + %g)', wTrig^2);
                    else
                        quadStr = sprintf('(%s^2 + %g)', sShiftStr, wTrig^2);
                        quadEval = sprintf('(%s.^2 + %g)', sShiftEval, wTrig^2);
                    end
                    
                    switch trigType
                        case 'sin'
                            fStr = sprintf('%g/%s', gain * wTrig, quadStr);
                            eStr = sprintf('(%g./%s)', gain * wTrig, quadEval);
                        case 'cos'
                            if gain == 1
                                fStr = sprintf('%s/%s', sShiftStr, quadStr);
                            else
                                fStr = sprintf('%g*%s/%s', gain, sShiftStr, quadStr);
                            end
                            eStr = sprintf('(%g.*%s./%s)', gain, sShiftEval, quadEval);
                        case 'sinh'
                            quadHStr = strrep(quadStr, '+', '-');
                            quadHEval = strrep(quadEval, '+', '-');
                            fStr = sprintf('%g/%s', gain * wTrig, quadHStr);
                            eStr = sprintf('(%g./%s)', gain * wTrig, quadHEval);
                        case 'cosh'
                            quadHStr = strrep(quadStr, '+', '-');
                            quadHEval = strrep(quadEval, '+', '-');
                            fStr = sprintf('%g*%s/%s', gain, sShiftStr, quadHStr);
                            eStr = sprintf('(%g.*%s./%s)', gain, sShiftEval, quadHEval);
                    end
                end
                
                outParts{end+1} = fStr; %#ok<AGROW>
                evalParts{end+1} = eStr; %#ok<AGROW>
                termNotes{end+1} = sprintf('  L{%s}  =  %s', tk, fStr); %#ok<AGROW>
            end
            
            Fs_str = strjoin(outParts, ' + ');
            Fs_str = strrep(Fs_str, '+ -', '- ');
            F_eval_fn = eval(['@(s) ' strjoin(evalParts, ' + ')]);
        end

        function [ft_str, pf_str, step3Lines, F_orig_fn, f_num_fn] = inverseLaplaceEngine(app, exprStr)
            % Evaluasi F(s) menjadi fungsi alih rasional memakai Control System Toolbox
            s = tf('s'); %#ok<NASGU>
            G_s = eval(exprStr);
            if ~isa(G_s, 'tf')
                error('Ekspresi F(s) harus berupa fungsi rasional dalam variabel s.');
            end
            [num, den] = tfdata(G_s, 'v');
            
            [pf_str, ft_str, ~, p, r, k] = app.partialFractionHelper(num, den);
            
            % Susun rincian langkah invers tiap suku
            step3Lines = {};
            idx = 1;
            nPoles = length(p);
            while idx <= nPoles
                if abs(imag(p(idx))) > 1e-6 && idx < nPoles && abs(p(idx+1) - conj(p(idx))) < 1e-5
                    p1 = p(idx); r1 = r(idx);
                    if imag(p1) < 0
                        p1 = p(idx+1); r1 = r(idx+1);
                    end
                    sig = real(p1); w = imag(p1);
                    a = real(r1); b = imag(r1);
                    step3Lines{end+1} = sprintf('  Pasangan pole kompleks %.4g +- %.4gi -> exp(%.4g*t)*(%g*cos(%.4g*t) %+g*sin(%.4g*t))', ...
                        sig, w, sig, 2*a, w, -2*b, w); %#ok<AGROW>
                    idx = idx + 2;
                else
                    mult = 1;
                    while (idx + mult <= nPoles) && (abs(p(idx + mult) - p(idx)) < 1e-5)
                        mult = mult + 1;
                    end
                    for m = 1:mult
                        rv = real(r(idx + m - 1));
                        pv = real(p(idx));
                        step3Lines{end+1} = sprintf('  L^-1{ %.4g / (s %+g)^%d } = %.4g * t^%d/%d! * exp(%.4g*t)', ...
                            rv, -pv, m, rv, m-1, m-1, pv); %#ok<AGROW>
                    end
                    idx = idx + mult;
                end
            end
            if ~isempty(k)
                step3Lines{end+1} = '  (Catatan: bagian polinom langsung menghasilkan impuls dirac(t))';
            end
            
            F_orig_fn = @(sv) polyval(num, sv) ./ polyval(den, sv);
            f_num_fn = eval(['@(t) ' vectorize(ft_str)]);
        end

        function [Fs_str, ft_str, detailRes, p, r, k] = partialFractionHelper(~, num, den)
            [r, p, k] = residue(num, den);
            
            pfTerms = {};
            ftTerms = {};
            detailRes = {};
            
            idx = 1;
            nPoles = length(p);
            while idx <= nPoles
                % Deteksi pasangan pole kompleks konjugat orde 1
                if abs(imag(p(idx))) > 1e-6 && idx < nPoles && abs(p(idx+1) - conj(p(idx))) < 1e-5
                    p1 = p(idx); r1 = r(idx);
                    p2 = p(idx+1); r2 = r(idx+1);
                    if imag(p1) < 0
                        [p1, p2] = deal(p2, p1);
                        [r1, r2] = deal(r2, r1);
                    end
                    sig = real(p1); w = imag(p1);
                    a = real(r1); b = imag(r1);
                    
                    pfTerms{end+1} = sprintf('(%.4g%+.4gi)/(s - (%.4g%+.4gi)) + (%.4g%+.4gi)/(s - (%.4g%+.4gi))', ...
                        real(r1), imag(r1), real(p1), imag(p1), real(r2), imag(r2), real(p2), imag(p2)); %#ok<AGROW>
                    
                    cCos = 2 * a;
                    cSin = -2 * b;
                    innerParts = {};
                    if abs(cCos) > 1e-7
                        innerParts{end+1} = sprintf('%.4g*cos(%.4g*t)', cCos, w); %#ok<AGROW>
                    end
                    if abs(cSin) > 1e-7
                        innerParts{end+1} = sprintf('%.4g*sin(%.4g*t)', cSin, w); %#ok<AGROW>
                    end
                    innerStr = strjoin(innerParts, ' + ');
                    if abs(sig) < 1e-7
                        ftTerms{end+1} = innerStr; %#ok<AGROW>
                    else
                        if length(innerParts) > 1
                            ftTerms{end+1} = sprintf('exp(%.4g*t)*(%s)', sig, innerStr); %#ok<AGROW>
                        else
                            ftTerms{end+1} = sprintf('exp(%.4g*t)*%s', sig, innerStr); %#ok<AGROW>
                        end
                    end
                    
                    detailRes{end+1} = sprintf('  pole %.4g%+.4gi : r = %.4g%+.4gi', real(p1), imag(p1), real(r1), imag(r1)); %#ok<AGROW>
                    detailRes{end+1} = sprintf('  pole %.4g%+.4gi : r = %.4g%+.4gi', real(p2), imag(p2), real(r2), imag(r2)); %#ok<AGROW>
                    idx = idx + 2;
                else
                    % Pole real (tunggal maupun berulang)
                    mult = 1;
                    while (idx + mult <= nPoles) && (abs(p(idx + mult) - p(idx)) < 1e-5)
                        mult = mult + 1;
                    end
                    
                    for m = 1:mult
                        resVal = real(r(idx + m - 1));
                        polReal = real(p(idx));
                        if abs(polReal) < 1e-9
                            denStr = 's';
                        elseif polReal > 0
                            denStr = sprintf('(s - %.4g)', polReal);
                        else
                            denStr = sprintf('(s + %.4g)', abs(polReal));
                        end
                        if m > 1
                            denStr = sprintf('%s^%d', denStr, m);
                        end
                        pfTerms{end+1} = sprintf('(%.4g)/%s', resVal, denStr); %#ok<AGROW>
                        
                        if abs(polReal) < 1e-9
                            if m == 1
                                ftTerms{end+1} = sprintf('%.4g', resVal); %#ok<AGROW>
                            else
                                ftTerms{end+1} = sprintf('(%.4g/%d)*t^%d', resVal, factorial(m-1), m-1); %#ok<AGROW>
                            end
                        else
                            if m == 1
                                ftTerms{end+1} = sprintf('%.4g*exp(%.4g*t)', resVal, polReal); %#ok<AGROW>
                            else
                                ftTerms{end+1} = sprintf('(%.4g/%d)*t^%d*exp(%.4g*t)', resVal, factorial(m-1), m-1, polReal); %#ok<AGROW>
                            end
                        end
                        detailRes{end+1} = sprintf('  pole %.4g (orde %d) : r = %.4g', polReal, m, resVal); %#ok<AGROW>
                    end
                    idx = idx + mult;
                end
            end
            
            if ~isempty(k)
                for kk = 1:length(k)
                    deg = length(k) - kk;
                    if deg == 0
                        pfTerms{end+1} = sprintf('%.4g', k(kk)); %#ok<AGROW>
                    else
                        pfTerms{end+1} = sprintf('%.4g*s^%d', k(kk), deg); %#ok<AGROW>
                    end
                end
            end
            
            Fs_str = strrep(strjoin(pfTerms, ' + '), '+ -', '- ');
            ft_str = strrep(strjoin(ftTerms, ' + '), '+ -', '- ');
            if isempty(ft_str)
                ft_str = '0';
            end
        end

        %% ================= LOGIKA ROOT LOCUS =================
        function plotRootLocus(app)
            num = str2num(app.RLNumEdit.Value); %#ok<ST2NM>
            den = str2num(app.RLDenEdit.Value); %#ok<ST2NM>
            kMax = app.RLKMaxEdit.Value;
            
            if isempty(num) || isempty(den) || ~isnumeric(num) || ~isnumeric(den) || all(den == 0)
                uialert(app.UIFigure, 'Numerator atau Denominator tidak valid! Masukkan array angka, misal [1 3 2 0].', ...
                    'Input Tidak Valid', 'Icon', 'error');
                return;
            end
            if kMax <= 0
                uialert(app.UIFigure, 'K maksimum harus lebih besar dari 0.', 'Input Tidak Valid', 'Icon', 'error');
                return;
            end
            
            app.RL_num = num;
            app.RL_den = den;
            app.RLKSlider.Limits = [0 kMax];
            if str2double(app.RLKEdit.Value) > kMax
                app.RLKEdit.Value = num2str(kMax / 2);
            end
            
            app.updateRootLocusAnalysis();
        end

        function onRLSliderChanged(app)
            kVal = app.RLKSlider.Value;
            app.RLKEdit.Value = sprintf('%.2f', kVal);
            app.updateRootLocusAnalysis();
        end

        function updateRootLocusAnalysis(app)
            kVal = str2double(app.RLKEdit.Value);
            if isnan(kVal) || ~isreal(kVal) || kVal < 0
                uialert(app.UIFigure, 'Nilai Gain K harus berupa angka non-negatif (Value must be numeric).', ...
                    'Input Gain Tidak Valid', 'Icon', 'error');
                return;
            end
            
            if kVal <= app.RLKSlider.Limits(2)
                app.RLKSlider.Value = kVal;
            end
            
            num = app.RL_num;
            den = app.RL_den;
            G = tf(num, den);
            kMax = app.RLKSlider.Limits(2);
            
            % Hitung lintasan Root Locus
            kVec = linspace(0, kMax, 600);
            rAll = rlocus(G, kVec);
            
            % Hitung pole & zero open-loop serta pole closed-loop saat K = kVal
            olPoles = pole(G);
            olZeros = zero(G);
            
            nOrder = max(length(num), length(den));
            numPad = [zeros(1, nOrder - length(num)), num];
            denPad = [zeros(1, nOrder - length(den)), den];
            clPoles = roots(denPad + kVal * numPad);
            
            % Plot Root Locus di UIAxes Kiri
            cla(app.RLAxes);
            hold(app.RLAxes, 'on');
            plot(app.RLAxes, real(rAll.'), imag(rAll.'), 'LineWidth', 1.4);
            xline(app.RLAxes, 0, ':k');
            yline(app.RLAxes, 0, ':k');
            if ~isempty(olPoles)
                plot(app.RLAxes, real(olPoles), imag(olPoles), 'kx', 'MarkerSize', 10, 'LineWidth', 2);
            end
            if ~isempty(olZeros)
                plot(app.RLAxes, real(olZeros), imag(olZeros), 'ko', 'MarkerSize', 9, 'LineWidth', 2);
            end
            if ~isempty(clPoles)
                plot(app.RLAxes, real(clPoles), imag(clPoles), 'rs', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
            end
            grid(app.RLAxes, 'on');
            xlabel(app.RLAxes, 'Real');
            ylabel(app.RLAxes, 'Imajiner');
            title(app.RLAxes, sprintf('Root Locus (Marker Merah: K = %.4g)', kVal));
            hold(app.RLAxes, 'off');
            
            % Plot Step Response Closed-Loop di UIAxes Kanan
            T_cl = feedback(kVal * G, 1);
            cla(app.RLStepAxes);
            [yStep, tStep] = step(T_cl);
            plot(app.RLStepAxes, tStep, yStep, 'Color', [0.09 0.49 0.52], 'LineWidth', 1.8);
            hold(app.RLStepAxes, 'on');
            yline(app.RLStepAxes, 1, ':k');
            grid(app.RLStepAxes, 'on');
            xlabel(app.RLStepAxes, 'Waktu (s)');
            ylabel(app.RLStepAxes, 'Amplitudo');
            title(app.RLStepAxes, sprintf('Step Response Closed-Loop (K = %.4g)', kVal));
            hold(app.RLStepAxes, 'off');
            
            % Tentukan Status Kestabilan
            maxReal = max(real(clPoles));
            if maxReal < -1e-5
                statusTxt = 'Status: STABIL';
                statusFull = 'STABIL (semua pole berada di sebelah kiri sumbu imajiner)';
                app.RLStatusLabel.FontColor = [0.05 0.55 0.25];
            elseif abs(maxReal) <= 1e-5
                statusTxt = 'Status: BATAS KESTABILAN';
                statusFull = 'BATAS KESTABILAN / marginal (pole tepat di sumbu imajiner)';
                app.RLStatusLabel.FontColor = [0.85 0.50 0.05];
            else
                statusTxt = 'Status: TIDAK STABIL';
                statusFull = 'TIDAK STABIL (ada pole di sebelah kanan sumbu imajiner)';
                app.RLStatusLabel.FontColor = [0.80 0.15 0.15];
            end
            app.RLStatusLabel.Text = statusTxt;
            
            % Estimasi K kritis (perpotongan sumbu imajiner)
            kCritInfo = 'Tidak menyeberang sumbu imajiner pada rentang K ini.';
            maxReVec = max(real(rAll), [], 1);
            crossIdx = find(maxReVec(1:end-1) < 0 & maxReVec(2:end) >= 0, 1, 'first');
            if ~isempty(crossIdx)
                try
                    kCrit = fzero(@(kk) max(real(roots(denPad + kk * numPad))), [kVec(crossIdx), kVec(crossIdx+1)]);
                    pCrit = roots(denPad + kCrit * numPad);
                    [~, imIdx] = min(abs(real(pCrit)));
                    wCrit = abs(imag(pCrit(imIdx)));
                    kCritInfo = sprintf('K kritis (pole menyeberang sumbu imajiner) = %.4g pada w = %.4g rad/s', kCrit, wCrit);
                catch
                end
            end
            
            olPolesStr = app.complexVecToStr(olPoles);
            olZerosStr = app.complexVecToStr(olZeros);
            clPolesStr = app.complexVecToStr(clPoles);
            
            app.RLInfoArea.Value = {
                'FUNGSI ALIH OPEN-LOOP G(s) = num/den:'
                ['  Numerator   : ' app.polyToString(num)]
                ['  Denominator : ' app.polyToString(den)]
                ''
                ['Pole open-loop  : ' olPolesStr]
                ['Zero open-loop  : ' olZerosStr]
                sprintf('Gain terpilih K = %.4g', kVal)
                ['Pole closed-loop (akar dari den + K*num = 0) : ' clPolesStr]
                ['KESTABILAN      : ' statusFull]
                kCritInfo
                ''
                'PENJELASAN HUBUNGAN GAIN - POLE - RESPONS:'
                '- K = 0 : pole closed-loop berimpit dengan pole open-loop.'
                '- K naik : pole bergerak sepanjang cabang locus menuju zero atau menuju tak hingga.'
                '- Pole bergerak ke kiri (makin negatif) -> respons makin cepat (settling time turun).'
                '- Pole menjadi kompleks, makin jauh dari sumbu real -> osilasi dan overshoot membesar.'
                '- Pole menyeberang sumbu imajiner di K kritis -> osilasi tak teredam (batas kestabilan).'
            };
        end

        %% ================= LOGIKA PID CONTROL PANEL =================
        function onPIDConfigChanged(app)
            cfg = app.PIDConfigDrop.Value;
            switch cfg
                case 'P'
                    app.PIDPCheck.Value = true;  app.PIDICheck.Value = false; app.PIDDCheck.Value = false;
                case 'PI'
                    app.PIDPCheck.Value = true;  app.PIDICheck.Value = true;  app.PIDDCheck.Value = false;
                case 'PD'
                    app.PIDPCheck.Value = true;  app.PIDICheck.Value = false; app.PIDDCheck.Value = true;
                case 'PID'
                    app.PIDPCheck.Value = true;  app.PIDICheck.Value = true;  app.PIDDCheck.Value = true;
            end
            app.simulatePID(false);
        end

        function onPIDCheckboxChanged(app)
            pOn = app.PIDPCheck.Value;
            iOn = app.PIDICheck.Value;
            dOn = app.PIDDCheck.Value;
            if pOn && ~iOn && ~dOn
                app.PIDConfigDrop.Value = 'P';
            elseif pOn && iOn && ~dOn
                app.PIDConfigDrop.Value = 'PI';
            elseif pOn && ~iOn && dOn
                app.PIDConfigDrop.Value = 'PD';
            elseif pOn && iOn && dOn
                app.PIDConfigDrop.Value = 'PID';
            else
                app.PIDConfigDrop.Value = 'Custom';
            end
            app.simulatePID(false);
        end

        function syncPIDSliderToEdit(app, which)
            switch which
                case 'Kp', app.PIDKpEdit.Value = round(app.PIDKpSlider.Value, 2);
                case 'Ki', app.PIDKiEdit.Value = round(app.PIDKiSlider.Value, 2);
                case 'Kd', app.PIDKdEdit.Value = round(app.PIDKdSlider.Value, 2);
            end
            app.simulatePID(false);
        end

        function syncPIDEditToSlider(app, which)
            switch which
                case 'Kp'
                    v = max(app.PIDKpSlider.Limits(1), min(app.PIDKpSlider.Limits(2), app.PIDKpEdit.Value));
                    app.PIDKpSlider.Value = v;
                case 'Ki'
                    v = max(app.PIDKiSlider.Limits(1), min(app.PIDKiSlider.Limits(2), app.PIDKiEdit.Value));
                    app.PIDKiSlider.Value = v;
                case 'Kd'
                    v = max(app.PIDKdSlider.Limits(1), min(app.PIDKdSlider.Limits(2), app.PIDKdEdit.Value));
                    app.PIDKdSlider.Value = v;
            end
            app.simulatePID(false);
        end

        function resetPID(app)
            app.PIDNumEdit.Value = '[1]';
            app.PIDDenEdit.Value = '[1 3 2]';
            app.PIDTsimEdit.Value = 10;
            app.PIDConfigDrop.Value = 'PID';
            app.PIDPCheck.Value = true;
            app.PIDICheck.Value = true;
            app.PIDDCheck.Value = true;
            app.PIDKpEdit.Value = 5;   app.PIDKpSlider.Value = 5;
            app.PIDKiEdit.Value = 2;   app.PIDKiSlider.Value = 2;
            app.PIDKdEdit.Value = 0.5; app.PIDKdSlider.Value = 0.5;
            app.PIDDistCheck.Value = true;
            app.PIDDistMagEdit.Value = 0.5;
            app.PIDDistTimeEdit.Value = 5;
            app.simulatePID(false);
        end

        function simulatePID(app, logToTable)
            num = str2num(app.PIDNumEdit.Value); %#ok<ST2NM>
            den = str2num(app.PIDDenEdit.Value); %#ok<ST2NM>
            tSim = app.PIDTsimEdit.Value;
            
            if isempty(num) || isempty(den) || ~isnumeric(num) || ~isnumeric(den) || all(den == 0) || tSim <= 0
                uialert(app.UIFigure, 'Parameter Plant atau Waktu Simulasi tidak valid.', 'Input Error', 'Icon', 'error');
                return;
            end
            
            Kp = app.PIDKpEdit.Value * double(app.PIDPCheck.Value);
            Ki = app.PIDKiEdit.Value * double(app.PIDICheck.Value);
            Kd = app.PIDKdEdit.Value * double(app.PIDDCheck.Value);
            
            G = tf(num, den);
            s = tf('s');
            C = Kp + Ki / s + (Kd * s) / (0.01 * s + 1);
            
            T_yr = feedback(C * G, 1);  % Setpoint -> Output
            T_yd = feedback(G, C);      % Input Disturbance -> Output
            
            t = linspace(0, tSim, 1000)';
            r = ones(size(t));
            
            y_ol = lsim(G, r, t);
            y_cl = lsim(T_yr, r, t);
            
            mOL = app.calcStepMetrics(t, y_ol, pole(G));
            mCL = app.calcStepMetrics(t, y_cl, pole(T_yr));
            
            app.PIDMetricTable.Data = {
                'Rise Time (10-90%)', mOL.TrStr, mCL.TrStr;
                'Settling Time (2%)',  mOL.TsStr, mCL.TsStr;
                'Peak Time',           mOL.TpStr, mCL.TpStr;
                'Max Overshoot',       mOL.OSStr, mCL.OSStr;
                'Steady-State Error',  mOL.EssStr, mCL.EssStr
            };
            
            % Plot 1: Perbandingan Step Response
            cla(app.PIDStepAxes);
            hold(app.PIDStepAxes, 'on');
            plot(app.PIDStepAxes, t, y_ol, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5);
            plot(app.PIDStepAxes, t, y_cl, '-', 'Color', [0.09 0.49 0.52], 'LineWidth', 2.0);
            plot(app.PIDStepAxes, t, r, ':k', 'LineWidth', 1.2);
            grid(app.PIDStepAxes, 'on');
            xlabel(app.PIDStepAxes, 'Waktu (s)');
            ylabel(app.PIDStepAxes, 'Keluaran');
            title(app.PIDStepAxes, 'Respons Step Setpoint');
            legend(app.PIDStepAxes, {'Plant tanpa pengendali', 'Dengan pengendali', 'Setpoint'}, 'Location', 'southeast');
            hold(app.PIDStepAxes, 'off');
            
            % Simulasi Disturbance
            distOn = app.PIDDistCheck.Value;
            dMag = app.PIDDistMagEdit.Value;
            tDist = app.PIDDistTimeEdit.Value;
            
            d = zeros(size(t));
            if distOn
                d(t >= tDist) = dMag;
            end
            y_ol_dist = lsim(G, r + d, t);
            y_cl_dist = y_cl + lsim(T_yd, d, t);
            
            % Plot 2: Respons dengan Gangguan
            cla(app.PIDDistAxes);
            hold(app.PIDDistAxes, 'on');
            plot(app.PIDDistAxes, t, r, ':k', 'LineWidth', 1.2);
            plot(app.PIDDistAxes, t, y_ol_dist, '--', 'Color', [0.55 0.55 0.55], 'LineWidth', 1.4);
            if distOn
                idxBefore = t <= tDist;
                idxAfter  = t >= tDist;
                plot(app.PIDDistAxes, t(idxBefore), y_cl_dist(idxBefore), '-', 'Color', [0.09 0.49 0.52], 'LineWidth', 2.0);
                plot(app.PIDDistAxes, t(idxAfter), y_cl_dist(idxAfter), '-', 'Color', [0.78 0.22 0.22], 'LineWidth', 2.0);
                xline(app.PIDDistAxes, tDist, '--', 'Color', [0.85 0.65 0.1], 'LineWidth', 1.3);
                legend(app.PIDDistAxes, {'Setpoint', 'Tanpa pengendali + gangguan', ...
                    'Sebelum gangguan (dengan pengendali)', 'Sesudah gangguan (dengan pengendali)', ...
                    sprintf('Gangguan t = %g s', tDist)}, 'Location', 'southeast');
            else
                plot(app.PIDDistAxes, t, y_cl_dist, '-', 'Color', [0.09 0.49 0.52], 'LineWidth', 2.0);
                legend(app.PIDDistAxes, {'Setpoint', 'Tanpa pengendali', 'Dengan pengendali'}, 'Location', 'southeast');
            end
            grid(app.PIDDistAxes, 'on');
            xlabel(app.PIDDistAxes, 'Waktu (s)');
            ylabel(app.PIDDistAxes, 'Keluaran');
            title(app.PIDDistAxes, 'Pengujian Gangguan (Disturbance)');
            hold(app.PIDDistAxes, 'off');
            
            clPoles = pole(T_yr);
            if max(real(clPoles)) < -1e-5
                stabStr = 'STABIL';
            elseif abs(max(real(clPoles))) <= 1e-5
                stabStr = 'BATAS KESTABILAN';
            else
                stabStr = 'TIDAK STABIL';
            end
            
            if distOn
                afterVals = y_cl_dist(t >= tDist);
                maxDev = max(abs(afterVals - 1));
                endErr = y_cl_dist(end) - 1;
                if abs(endErr) < 0.02
                    recovStr = 'KEMBALI ke setpoint (error akhir < 2%)';
                else
                    recovStr = 'BELUM kembali penuh ke setpoint (perlu aksi Integral Ki)';
                end
                distSummary = sprintf([ ...
                    'Gangguan %.3g pada t = %g s: simpangan maks = %.5g\n' ...
                    'Error akhir setelah gangguan = %.5g -> %s'], dMag, tDist, maxDev, endErr, recovStr);
            else
                distSummary = 'Gangguan dinonaktifkan.';
            end
            
            app.PIDSummaryArea.Value = {
                sprintf('Pengendali: %s  (Kp = %.3g, Ki = %.3g, Kd = %.3g)', app.PIDConfigDrop.Value, Kp, Ki, Kd)
                ['Closed-loop: ' stabStr]
                ['Pole CL: ' app.complexVecToStr(clPoles)]
                distSummary
                '(Catatan: Kp mempercepat respons, Ki menghilangkan steady-state error & gangguan konstan, Kd meredam overshoot.)'
            };
            
            if logToTable
                app.PID_ExpCount = app.PID_ExpCount + 1;
                newRow = {app.PID_ExpCount, app.PIDConfigDrop.Value, Kp, Ki, Kd, ...
                          mCL.TrStr, mCL.TsStr, mCL.TpStr, mCL.OSStr, mCL.EssStr};
                app.PIDLogTable.Data = [app.PIDLogTable.Data; newRow];
            end
        end

        %% ================= LOGIKA BLACK BOX (BONUS) =================
        function loadBlackBoxCSV(app)
            [file, path] = uigetfile('*.csv', 'Pilih File Data CSV (kolom: t, u, y)');
            if isequal(file, 0)
                return;
            end
            try
                data = readmatrix(fullfile(path, file));
                data = data(all(~isnan(data(:, 1:3)), 2), :);
                if size(data, 2) < 3 || size(data, 1) < 10
                    error('File CSV minimal memiliki 3 kolom (t, u, y) dan 10 baris data.');
                end
                app.BB_t = data(:, 1);
                app.BB_u = data(:, 2);
                app.BB_y = data(:, 3);
                app.BBInfoLabel.Text = sprintf('File: %s\n%d sampel, t = %.3g ... %.3g s\nInput: %.3g ... %.3g | Output: %.3g ... %.3g', ...
                    file, length(app.BB_t), min(app.BB_t), max(app.BB_t), min(app.BB_u), max(app.BB_u), min(app.BB_y), max(app.BB_y));
            catch ME
                uialert(app.UIFigure, ['Gagal membaca CSV: ' ME.message], 'Error File', 'Icon', 'error');
            end
        end

        function loadBlackBoxDemo(app)
            t = linspace(0, 20, 401)';
            u = double(t >= 1);
            G_true = tf(4.45, [1 1.05 2.225]);
            rng(42);
            y = lsim(G_true, u, t) + 0.008 * randn(size(t));
            
            app.BB_t = t;
            app.BB_u = u;
            app.BB_y = y;
            app.BBInfoLabel.Text = sprintf('Data DEMO (bukan data tugas)\n%d sampel, t = 0 ... 20 s\nInput: %.3g ... %.3g\nOutput: %.4g ... %.4g', ...
                length(t), min(u), max(u), min(y), max(y));
        end

        function runBlackBoxIdentification(app)
            if isempty(app.BB_t)
                uialert(app.UIFigure, 'Muat file CSV terlebih dahulu atau klik "Gunakan data demo".', 'Data Kosong', 'Icon', 'warning');
                return;
            end
            
            t = app.BB_t(:);
            u = app.BB_u(:);
            y = app.BB_y(:);
            
            % LANGKAH 1: Amati data input/output & deteksi waktu step
            du = abs(diff(u));
            [~, stepIdx] = max(du);
            if max(du) < 1e-6
                stepIdx = 1;
            end
            tStep = t(stepIdx);
            
            uAwal = mean(u(1:max(1, stepIdx)));
            uAkhir = mean(u(max(stepIdx+1, end-20):end));
            yAwal = mean(y(1:max(1, stepIdx)));
            yAkhir = mean(y(max(stepIdx+1, end-20):end));
            
            % LANGKAH 2: Gain statis K
            K = (yAkhir - yAwal) / (uAkhir - uAwal);
            
            % LANGKAH 3: Normalisasi respons setelah tStep
            tRel = t(stepIdx:end) - tStep;
            yNorm = (y(stepIdx:end) - yAwal) / (K * (uAkhir - uAwal));
            
            [yPeak, peakIdx] = max(yNorm);
            Mp = max(0, (yPeak - 1) * 100);
            tp = tRel(peakIdx);
            
            idx28 = find(yNorm >= 0.283, 1, 'first');
            idx63 = find(yNorm >= 0.632, 1, 'first');
            if isempty(idx28), idx28 = 2; end
            if isempty(idx63), idx63 = max(3, idx28 + 1); end
            t28 = tRel(idx28);
            t63 = tRel(idx63);
            
            % LANGKAH 4: Perkiraan orde awal
            if Mp > 2
                orderReason = sprintf('Ada overshoot > 2%% (Mp = %.2f%%) dan osilasi teredam -> sistem minimal ORDE 2 (underdamped).', Mp);
            else
                orderReason = sprintf('Overshoot <= 2%% (Mp = %.2f%%) -> sistem cenderung ORDE 1 atau ORDE 2 overdamped.', Mp);
            end
            
            % LANGKAH 5: Bangun 4 Model Kandidat
            tau1 = max(1e-3, t63);
            G1 = tf(K, [tau1 1]);
            y1 = yAwal + lsim(G1, u - uAwal, t);
            [rmse1, fit1] = app.calcFitMetrics(y, y1);
            strG1 = sprintf('G(s) = %.4g / (%.4g s + 1)', K, tau1);
            
            tau2 = max(1e-3, 1.5 * (t63 - t28));
            theta2 = max(0, t63 - tau2);
            G2 = tf(K, [tau2 1], 'InputDelay', theta2);
            y2 = yAwal + lsim(G2, u - uAwal, t);
            [rmse2, fit2] = app.calcFitMetrics(y, y2);
            strG2 = sprintf('G(s) = %.4g e^(-%.4g s) / (%.4g s + 1)', K, theta2, tau2);
            
            if Mp > 1
                zeta0 = -log(Mp/100) / sqrt(pi^2 + (log(Mp/100))^2);
                wn0 = pi / (max(1e-3, tp) * sqrt(1 - zeta0^2));
            else
                zeta0 = 0.8;
                wn0 = 2 / max(1e-3, t63);
            end
            cost3 = @(p) norm(y - (yAwal + lsim(tf(K*abs(p(1))^2, [1 2*abs(p(2))*abs(p(1)) abs(p(1))^2]), u - uAwal, t)));
            pOpt3 = fminsearch(cost3, [wn0, zeta0], optimset('Display', 'off'));
            wn3 = abs(pOpt3(1)); zeta3 = abs(pOpt3(2));
            G3 = tf(K * wn3^2, [1, 2*zeta3*wn3, wn3^2]);
            y3 = yAwal + lsim(G3, u - uAwal, t);
            [rmse3, fit3] = app.calcFitMetrics(y, y3);
            strG3 = sprintf('G(s) = %.4g / (s^2 + %.4g s + %.4g) [wn=%.4g, zeta=%.4g]', ...
                K*wn3^2, 2*zeta3*wn3, wn3^2, wn3, zeta3);
            
            cost4 = @(p) norm(y - (yAwal + lsim(tf(K*abs(p(1))^2, [1 2*abs(p(2))*abs(p(1)) abs(p(1))^2], 'InputDelay', max(0, p(3))), u - uAwal, t)));
            pOpt4 = fminsearch(cost4, [wn3, zeta3, 0.05], optimset('Display', 'off'));
            wn4 = abs(pOpt4(1)); zeta4 = abs(pOpt4(2)); theta4 = max(0, pOpt4(3));
            G4 = tf(K * wn4^2, [1, 2*zeta4*wn4, wn4^2], 'InputDelay', theta4);
            y4 = yAwal + lsim(G4, u - uAwal, t);
            [rmse4, fit4] = app.calcFitMetrics(y, y4);
            strG4 = sprintf('G(s) = %.4g e^(-%.4g s) / (s^2 + %.4g s + %.4g)', ...
                K*wn4^2, theta4, 2*zeta4*wn4, wn4^2);
            
            % LANGKAH 6: Prinsip Parsimoni
            fits = [fit1, fit2, fit3, fit4];
            yModels = {y1, y2, y3, y4};
            names = {'Orde-1', 'Orde-1 + delay', 'Orde-2 underdamped', 'Orde-2 + delay (LS)'};
            bestFit = max(fits);
            selIdx = find(fits >= (bestFit - 1.0), 1, 'first');
            
            rowLabels = names;
            rowLabels{selIdx} = ['* ' rowLabels{selIdx}];
            app.BBModelTable.Data = {
                rowLabels{1}, 1, round(rmse1, 5), round(fit1, 2), strG1;
                rowLabels{2}, 1, round(rmse2, 5), round(fit2, 2), strG2;
                rowLabels{3}, 2, round(rmse3, 5), round(fit3, 2), strG3;
                rowLabels{4}, 2, round(rmse4, 5), round(fit4, 2), strG4
            };
            
            cla(app.BBAxes);
            hold(app.BBAxes, 'on');
            plot(app.BBAxes, t, y, '.', 'Color', [0.45 0.45 0.45], 'MarkerSize', 6);
            styles = {'--', '-.', ':', '--'};
            for m = 1:4
                if m == selIdx
                    plot(app.BBAxes, t, yModels{m}, '-', 'Color', [0.75 0.15 0.15], 'LineWidth', 2.2);
                else
                    plot(app.BBAxes, t, yModels{m}, styles{m}, 'LineWidth', 1.3);
                end
            end
            grid(app.BBAxes, 'on');
            xlabel(app.BBAxes, 'Waktu (s)');
            ylabel(app.BBAxes, 'Keluaran');
            title(app.BBAxes, ['MODEL TERPILIH: ' names{selIdx}]);
            legend(app.BBAxes, [{'Data aktual'}, names], 'Location', 'southeast');
            hold(app.BBAxes, 'off');
            
            app.BBStepsArea.Value = {
                'LANGKAH 1 - Amati data input/output'
                sprintf('  Input step: %.4g -> %.4g pada t = %.4g s', uAwal, uAkhir, tStep)
                sprintf('  Output    : %.5g -> %.5g (awal -> akhir)', yAwal, yAkhir)
                ''
                'LANGKAH 2 - Gain statis'
                sprintf('  K = (y_akhir - y_awal)/(u_akhir - u_awal) = %.4g / %.4g = %.4g', ...
                    yAkhir - yAwal, uAkhir - uAwal, K)
                ''
                'LANGKAH 3 - Ukuran respons ternormalisasi'
                sprintf('  Overshoot Mp = %.2f %%, waktu puncak tp = %.4g s', Mp, tp)
                sprintf('  t28.3%% = %.4g s, t63.2%% = %.4g s', t28, t63)
                ''
                'LANGKAH 4 - Tentukan orde'
                ['  ' orderReason]
                ''
                'LANGKAH 5 - Bandingkan model kandidat dengan data (RMSE dan Fit%)'
                sprintf('  Orde-1             : RMSE = %.5f | Fit = %.2f %%', rmse1, fit1)
                sprintf('  Orde-1 + delay     : RMSE = %.5f | Fit = %.2f %%', rmse2, fit2)
                sprintf('  Orde-2 underdamped : RMSE = %.5f | Fit = %.2f %%', rmse3, fit3)
                sprintf('  Orde-2 + delay (LS): RMSE = %.5f | Fit = %.2f %%', rmse4, fit4)
                ''
                'LANGKAH 6 - Alasan pemilihan (Prinsip Parsimoni)'
                sprintf('  Model terbaik Fit = %.2f %%. Dipilih model paling sederhana dengan Fit >= %.2f %% -> %s.', ...
                    bestFit, bestFit - 1.0, names{selIdx})
            };
        end

        %% ================= HELPER FUNGSI =================
        function s = polyToString(~, c)
            n = length(c);
            terms = {};
            for i = 1:n
                val = c(i);
                deg = n - i;
                if abs(val) < 1e-9 && n > 1
                    continue;
                end
                if deg == 0
                    terms{end+1} = sprintf('%.4g', val); %#ok<AGROW>
                elseif deg == 1
                    terms{end+1} = sprintf('%.4g s', val); %#ok<AGROW>
                else
                    terms{end+1} = sprintf('%.4g s^%d', val, deg); %#ok<AGROW>
                end
            end
            if isempty(terms)
                s = '0';
            else
                s = strjoin(terms, ' + ');
            end
        end

        function s = complexVecToStr(~, v)
            if isempty(v)
                s = '(tidak ada)';
                return;
            end
            parts = cell(1, length(v));
            for i = 1:length(v)
                if abs(imag(v(i))) < 1e-6
                    parts{i} = sprintf('%.4g', real(v(i)));
                else
                    parts{i} = sprintf('%.4g %+.4gi', real(v(i)), imag(v(i)));
                end
            end
            s = strjoin(parts, ',  ');
        end

        function m = calcStepMetrics(~, t, y, poles)
            if any(real(poles) >= 1e-5) || any(isnan(y)) || max(abs(y)) > 1e5
                m.TrStr = 'Tidak Stabil';
                m.TsStr = 'Tidak Stabil';
                m.TpStr = 'Tidak Stabil';
                m.OSStr = 'Tidak Stabil';
                m.EssStr = 'Inf';
                return;
            end
            info = stepinfo(y, t);
            m.TrStr  = sprintf('%.3f s', info.RiseTime);
            m.TsStr  = sprintf('%.3f s', info.SettlingTime);
            m.TpStr  = sprintf('%.3f s', info.PeakTime);
            m.OSStr  = sprintf('%.2f %%', info.Overshoot);
            m.EssStr = sprintf('%.4f', abs(1 - y(end)));
        end

        function [rmse, fitPct] = calcFitMetrics(~, yAct, yHat)
            rmse = sqrt(mean((yAct - yHat).^2));
            denom = norm(yAct - mean(yAct));
            if denom < 1e-12
                fitPct = 0;
            else
                fitPct = max(0, 100 * (1 - norm(yAct - yHat) / denom));
            end
        end

        %% ================= PEMBANGUNAN ANTARMUKA (UI) =================
        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [80 60 1240 740];
            app.UIFigure.Name = 'Control Engineering Lab';
            
            app.MainGrid = uigridlayout(app.UIFigure, [1 1]);
            app.MainGrid.Padding = [0 0 0 0];
            
            app.buildLoginUI();
            app.buildMenuUI();
            app.buildLaplaceUI();
            app.buildRootLocusUI();
            app.buildPIDUI();
            app.buildBlackBoxUI();
            app.buildProfileUI();
            
            app.showPage(app.LoginPanel);
            app.UIFigure.Visible = 'on';
        end

        function buildLoginUI(app)
            app.LoginPanel = uipanel(app.MainGrid, 'BackgroundColor', [0.07 0.14 0.23], 'BorderType', 'none');
            app.LoginPanel.Layout.Row = 1; app.LoginPanel.Layout.Column = 1;
            
            gOuter = uigridlayout(app.LoginPanel, [3 3]);
            gOuter.RowHeight = {'1x', 450, '1x'};
            gOuter.ColumnWidth = {'1x', 440, '1x'};
            
            card = uipanel(gOuter, 'BackgroundColor', [1 1 1], 'BorderType', 'line');
            card.Layout.Row = 2; card.Layout.Column = 2;
            
            g = uigridlayout(card, [9 2]);
            g.RowHeight = {45, 24, 24, 36, 24, 36, 24, 44, 38};
            g.ColumnWidth = {'1x', '1x'};
            g.Padding = [35 25 35 20];
            
            t1 = uilabel(g, 'Text', 'Control Engineering Lab', 'FontSize', 22, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', 'FontColor', [0.07 0.14 0.23]);
            t1.Layout.Row = 1; t1.Layout.Column = [1 2];
            
            t2 = uilabel(g, 'Text', 'Sistem Kendali 1 - silakan login', 'FontSize', 12, ...
                'HorizontalAlignment', 'center', 'FontColor', [0.4 0.4 0.4]);
            t2.Layout.Row = 2; t2.Layout.Column = [1 2];
            
            lu = uilabel(g, 'Text', 'Username', 'FontWeight', 'bold');
            lu.Layout.Row = 3; lu.Layout.Column = [1 2];
            app.UserEdit = uieditfield(g, 'text', 'Placeholder', 'Masukan Username');
            app.UserEdit.Layout.Row = 4; app.UserEdit.Layout.Column = [1 2];
            
            lp = uilabel(g, 'Text', 'Password', 'FontWeight', 'bold');
            lp.Layout.Row = 5; lp.Layout.Column = [1 2];
            app.PassEdit = uieditfield(g, 'text', 'Placeholder', 'Masukan Password', ...
                'ValueChangingFcn', @(~, event) app.onPasswordChanging(event));
            app.PassEdit.Layout.Row = 6; app.PassEdit.Layout.Column = [1 2];
            
            app.ShowPassCheck = uicheckbox(g, 'Text', 'Tampilkan password', 'Value', false, ...
                'ValueChangedFcn', @(~,~) app.togglePassword());
            app.ShowPassCheck.Layout.Row = 7; app.ShowPassCheck.Layout.Column = [1 2];
            
            btnIn = uibutton(g, 'Text', 'Login', 'BackgroundColor', [0.09 0.49 0.52], ...
                'FontColor', [1 1 1], 'FontWeight', 'bold', 'FontSize', 13, ...
                'ButtonPushedFcn', @(~,~) app.doLogin());
            btnIn.Layout.Row = 8; btnIn.Layout.Column = 1;
            
            btnOut = uibutton(g, 'Text', 'Exit', 'BackgroundColor', [0.78 0.22 0.22], ...
                'FontColor', [1 1 1], 'FontWeight', 'bold', 'FontSize', 13, ...
                'ButtonPushedFcn', @(~,~) delete(app.UIFigure));
            btnOut.Layout.Row = 8; btnOut.Layout.Column = 2;
            
            foot = uilabel(g, 'Text', 'Tugas Rancang - Understand the system, analyze the response, control the behavior.', ...
                'FontSize', 10, 'HorizontalAlignment', 'center', 'WordWrap', 'on', 'FontColor', [0.45 0.45 0.45]);
            foot.Layout.Row = 9; foot.Layout.Column = [1 2];
        end

        function buildMenuUI(app)
            app.MenuPanel = uipanel(app.MainGrid, 'BackgroundColor', [0.94 0.96 0.98], 'BorderType', 'none');
            app.MenuPanel.Layout.Row = 1; app.MenuPanel.Layout.Column = 1;
            
            g = uigridlayout(app.MenuPanel, [4 3]);
            g.RowHeight = {75, '1x', '1x', 50};
            g.ColumnWidth = {'1x', '1x', '1x'};
            g.Padding = [30 20 30 20];
            g.RowSpacing = 20;
            g.ColumnSpacing = 20;
            
            hdr = uilabel(g, 'Text', 'Control Engineering Lab — Main Menu', ...
                'FontSize', 22, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
                'FontColor', [0.07 0.14 0.23]);
            hdr.Layout.Row = 1; hdr.Layout.Column = [1 3];
            
            items = {
                '1. Laplace Calculator', 'Transformasi, invers, pecahan parsial', @(~,~) app.showPage(app.LaplacePanel), [0.09 0.49 0.52];
                '2. Root Locus', 'Pole-zero, gain K, kestabilan', @(~,~) app.openRootLocus(), [0.12 0.38 0.58];
                '3. PID Control Panel', 'Tuning P, PI, PD, PID + gangguan', @(~,~) app.openPID(), [0.15 0.30 0.52];
                '4. Black Box Control System (Bonus)', 'Identifikasi model dari data I/O', @(~,~) app.showPage(app.BlackBoxPanel), [0.22 0.42 0.32];
                '5. Developer Profile', 'Profil pembuat aplikasi', @(~,~) app.showPage(app.ProfilePanel), [0.30 0.35 0.45];
                '6. Exit Application', 'Tutup aplikasi', @(~,~) delete(app.UIFigure), [0.75 0.22 0.22]
            };
            
            for k = 1:6
                r = floor((k-1)/3) + 2;
                c = mod(k-1, 3) + 1;
                btn = uibutton(g, 'Text', sprintf('%s\n\n%s', items{k,1}, items{k,2}), ...
                    'BackgroundColor', items{k,4}, 'FontColor', [1 1 1], ...
                    'FontSize', 14, 'FontWeight', 'bold', 'WordWrap', 'on', ...
                    'ButtonPushedFcn', items{k,3});
                btn.Layout.Row = r;
                btn.Layout.Column = c;
            end
            
            btnLogout = uibutton(g, 'Text', 'Logout', 'BackgroundColor', [0.85 0.55 0.12], ...
                'FontColor', [1 1 1], 'FontWeight', 'bold', 'FontSize', 13, ...
                'ButtonPushedFcn', @(~,~) app.doLogout());
            btnLogout.Layout.Row = 4; btnLogout.Layout.Column = 2;
        end

        function buildLaplaceUI(app)
            app.LaplacePanel = uipanel(app.MainGrid, 'BackgroundColor', [0.95 0.96 0.98], 'BorderType', 'none');
            app.LaplacePanel.Layout.Row = 1; app.LaplacePanel.Layout.Column = 1;
            
            g = uigridlayout(app.LaplacePanel, [2 2]);
            g.RowHeight = {46, '1x'};
            g.ColumnWidth = {360, '1x'};
            app.createTopBar(g, 'Laplace Calculator');
            
            leftP = uipanel(g, 'BackgroundColor', [1 1 1]);
            leftP.Layout.Row = 2; leftP.Layout.Column = 1;
            gl = uigridlayout(leftP, [8 2]);
            gl.RowHeight = {34, 24, 34, 24, 34, 65, 40, '1x'};
            gl.ColumnWidth = {'1x', '1x'};
            
            app.LapModeDrop = uidropdown(gl, 'Items', {'Transformasi Laplace', 'Invers Laplace', 'Pecahan Parsial'}, ...
                'ValueChangedFcn', @(~,~) app.onLaplaceModeChanged());
            app.LapModeDrop.Layout.Row = 1; app.LapModeDrop.Layout.Column = [1 2];
            
            app.LapLabel1 = uilabel(gl, 'Text', 'f(t) =', 'FontWeight', 'bold');
            app.LapLabel1.Layout.Row = 2; app.LapLabel1.Layout.Column = [1 2];
            app.LapEdit1 = uieditfield(gl, 'text', 'Value', 'exp(-2*t)*sin(3*t)');
            app.LapEdit1.Layout.Row = 3; app.LapEdit1.Layout.Column = [1 2];
            
            app.LapLabel2 = uilabel(gl, 'Text', 'Denominator D(s):', 'FontWeight', 'bold', 'Visible', 'off');
            app.LapLabel2.Layout.Row = 4; app.LapLabel2.Layout.Column = [1 2];
            app.LapEdit2 = uieditfield(gl, 'text', 'Value', '[1 3 2]', 'Visible', 'off');
            app.LapEdit2.Layout.Row = 5; app.LapEdit2.Layout.Column = [1 2];
            
            app.LapHintLabel = uilabel(gl, 'Text', 'Gunakan variabel t. Contoh: 5*t^2 + 3, exp(-2*t)*sin(3*t), t*exp(-t), cos(4*t), heaviside(t-1)', ...
                'WordWrap', 'on', 'FontSize', 11, 'FontColor', [0.35 0.35 0.35]);
            app.LapHintLabel.Layout.Row = 6; app.LapHintLabel.Layout.Column = [1 2];
            
            bCalc = uibutton(gl, 'Text', 'Hitung', 'BackgroundColor', [0.09 0.49 0.52], ...
                'FontColor', [1 1 1], 'FontWeight', 'bold', 'ButtonPushedFcn', @(~,~) app.computeLaplace());
            bCalc.Layout.Row = 7; bCalc.Layout.Column = 1;
            
            bRes = uibutton(gl, 'Text', 'Reset', 'ButtonPushedFcn', @(~,~) app.resetLaplace());
            bRes.Layout.Row = 7; bRes.Layout.Column = 2;
            
            note = uilabel(gl, 'Text', ['Catatan: Perhitungan dijalankan langsung memakai tabel sifat Laplace, ' ...
                'dekomposisi residu (residue), dan verifikasi integral numerik tanpa memerlukan toolbox simbolik tambahan. ' ...
                'Setiap hasil disertai langkah matematis lengkap.'], ...
                'WordWrap', 'on', 'VerticalAlignment', 'top', 'FontSize', 11, 'FontColor', [0.3 0.3 0.3]);
            note.Layout.Row = 8; note.Layout.Column = [1 2];
            
            rightP = uipanel(g, 'BackgroundColor', [1 1 1]);
            rightP.Layout.Row = 2; rightP.Layout.Column = 2;
            gr = uigridlayout(rightP, [4 1]);
            gr.RowHeight = {24, 130, 26, '1x'};
            
            lOut = uilabel(gr, 'Text', 'Hasil Perhitungan', 'FontWeight', 'bold', 'FontSize', 13);
            lOut.Layout.Row = 1;
            app.LapResultArea = uitextarea(gr, 'Editable', 'off', 'FontName', 'Consolas', 'FontSize', 13);
            app.LapResultArea.Layout.Row = 2;
            
            lStep = uilabel(gr, 'Text', 'Langkah / proses matematis', 'FontWeight', 'bold', 'FontSize', 13);
            lStep.Layout.Row = 3;
            app.LapStepsArea = uitextarea(gr, 'Editable', 'off', 'FontName', 'Consolas', 'FontSize', 12);
            app.LapStepsArea.Layout.Row = 4;
        end

        function openRootLocus(app)
            app.showPage(app.RootLocusPanel);
            app.plotRootLocus();
        end

        function buildRootLocusUI(app)
            app.RootLocusPanel = uipanel(app.MainGrid, 'BackgroundColor', [0.95 0.96 0.98], 'BorderType', 'none');
            app.RootLocusPanel.Layout.Row = 1; app.RootLocusPanel.Layout.Column = 1;
            
            g = uigridlayout(app.RootLocusPanel, [2 2]);
            g.RowHeight = {46, '1x'};
            g.ColumnWidth = {320, '1x'};
            app.createTopBar(g, 'Root Locus Analysis');
            
            leftP = uipanel(g, 'BackgroundColor', [1 1 1]);
            leftP.Layout.Row = 2; leftP.Layout.Column = 1;
            gl = uigridlayout(leftP, [11 2]);
            gl.RowHeight = {22, 32, 22, 32, 32, 38, 28, 34, 34, 28, '1x'};
            gl.ColumnWidth = {'1x', '1x'};
            
            l1 = uilabel(gl, 'Text', 'Numerator', 'FontWeight', 'bold'); l1.Layout.Row = 1; l1.Layout.Column = [1 2];
            app.RLNumEdit = uieditfield(gl, 'text', 'Value', '[1]'); app.RLNumEdit.Layout.Row = 2; app.RLNumEdit.Layout.Column = [1 2];
            
            l2 = uilabel(gl, 'Text', 'Denominator', 'FontWeight', 'bold'); l2.Layout.Row = 3; l2.Layout.Column = [1 2];
            app.RLDenEdit = uieditfield(gl, 'text', 'Value', '[1 3 2 0]'); app.RLDenEdit.Layout.Row = 4; app.RLDenEdit.Layout.Column = [1 2];
            
            l3 = uilabel(gl, 'Text', 'K maksimum untuk plot locus'); l3.Layout.Row = 5; l3.Layout.Column = 1;
            app.RLKMaxEdit = uieditfield(gl, 'numeric', 'Value', 20); app.RLKMaxEdit.Layout.Row = 5; app.RLKMaxEdit.Layout.Column = 2;
            
            bPlot = uibutton(gl, 'Text', 'Plot Root Locus', 'BackgroundColor', [0.09 0.49 0.52], ...
                'FontColor', [1 1 1], 'FontWeight', 'bold', 'ButtonPushedFcn', @(~,~) app.plotRootLocus());
            bPlot.Layout.Row = 6; bPlot.Layout.Column = [1 2];
            
            l4 = uilabel(gl, 'Text', 'Pengaturan gain K', 'FontWeight', 'bold', 'FontSize', 13); l4.Layout.Row = 7; l4.Layout.Column = [1 2];
            app.RLKSlider = uislider(gl, 'Limits', [0 20], 'Value', 1, 'ValueChangedFcn', @(~,~) app.onRLSliderChanged());
            app.RLKSlider.Layout.Row = 8; app.RLKSlider.Layout.Column = [1 2];
            
            app.RLKEdit = uieditfield(gl, 'text', 'Value', '1'); app.RLKEdit.Layout.Row = 9; app.RLKEdit.Layout.Column = 1;
            bAnal = uibutton(gl, 'Text', 'Analisis', 'FontWeight', 'bold', 'ButtonPushedFcn', @(~,~) app.updateRootLocusAnalysis());
            bAnal.Layout.Row = 9; bAnal.Layout.Column = 2;
            
            app.RLStatusLabel = uilabel(gl, 'Text', 'Status: STABIL', 'FontWeight', 'bold', 'FontSize', 13, 'FontColor', [0.05 0.55 0.25]);
            app.RLStatusLabel.Layout.Row = 10; app.RLStatusLabel.Layout.Column = [1 2];
            
            tip = uilabel(gl, 'Text', ['Tips: geser slider atau ketik nilai K. Marker merah pada grafik adalah pole closed-loop ' ...
                'pada K terpilih. Contoh G(s) = 1/(s(s+1)(s+2)): sistem menjadi tidak stabil untuk K > 6.'], ...
                'WordWrap', 'on', 'VerticalAlignment', 'top', 'FontSize', 11, 'FontColor', [0.35 0.35 0.35]);
            tip.Layout.Row = 11; tip.Layout.Column = [1 2];
            
            rightP = uipanel(g, 'BackgroundColor', [1 1 1]);
            rightP.Layout.Row = 2; rightP.Layout.Column = 2;
            gr = uigridlayout(rightP, [2 2]);
            gr.RowHeight = {'1.2x', '1x'};
            gr.ColumnWidth = {'1x', '1x'};
            
            app.RLAxes = uiaxes(gr); app.RLAxes.Layout.Row = 1; app.RLAxes.Layout.Column = 1;
            app.RLStepAxes = uiaxes(gr); app.RLStepAxes.Layout.Row = 1; app.RLStepAxes.Layout.Column = 2;
            
            app.RLInfoArea = uitextarea(gr, 'Editable', 'off', 'FontName', 'Consolas', 'FontSize', 11.5);
            app.RLInfoArea.Layout.Row = 2; app.RLInfoArea.Layout.Column = [1 2];
        end

        function openPID(app)
            app.showPage(app.PIDPanel);
            app.simulatePID(false);
        end

        function buildPIDUI(app)
            app.PIDPanel = uipanel(app.MainGrid, 'BackgroundColor', [0.95 0.96 0.98], 'BorderType', 'none');
            app.PIDPanel.Layout.Row = 1; app.PIDPanel.Layout.Column = 1;
            
            g = uigridlayout(app.PIDPanel, [2 2]);
            g.RowHeight = {46, '1x'};
            g.ColumnWidth = {320, '1x'};
            app.createTopBar(g, 'PID Control Panel');
            
            leftP = uipanel(g, 'BackgroundColor', [1 1 1]);
            leftP.Layout.Row = 2; leftP.Layout.Column = 1;
            gl = uigridlayout(leftP, [14 4]);
            gl.RowHeight = {26, 26, 26, 24, 28, 26, 30, 30, 30, 24, 24, 26, 26, 36};
            gl.ColumnWidth = {85, '1x', '1x', 62};
            gl.RowSpacing = 4;
            
            lblNum = uilabel(gl, 'Text', 'Numerator'); lblNum.Layout.Row = 1;
            app.PIDNumEdit = uieditfield(gl, 'text', 'Value', '[1]'); app.PIDNumEdit.Layout.Row = 1; app.PIDNumEdit.Layout.Column = [2 4];
            
            lblDen = uilabel(gl, 'Text', 'Denominator'); lblDen.Layout.Row = 2;
            app.PIDDenEdit = uieditfield(gl, 'text', 'Value', '[1 3 2]'); app.PIDDenEdit.Layout.Row = 2; app.PIDDenEdit.Layout.Column = [2 4];
            
            lblTsim = uilabel(gl, 'Text', 'Waktu sim (s)'); lblTsim.Layout.Row = 3;
            app.PIDTsimEdit = uieditfield(gl, 'numeric', 'Value', 10); app.PIDTsimEdit.Layout.Row = 3; app.PIDTsimEdit.Layout.Column = [2 4];
            
            lCfg = uilabel(gl, 'Text', 'PENGENDALI', 'FontWeight', 'bold', 'FontColor', [0.09 0.49 0.52]);
            lCfg.Layout.Row = 4; lCfg.Layout.Column = [1 4];
            
            lblCfg = uilabel(gl, 'Text', 'Konfigurasi'); lblCfg.Layout.Row = 5;
            app.PIDConfigDrop = uidropdown(gl, 'Items', {'P', 'PI', 'PD', 'PID', 'Custom'}, 'Value', 'PID', ...
                'ValueChangedFcn', @(~,~) app.onPIDConfigChanged());
            app.PIDConfigDrop.Layout.Row = 5; app.PIDConfigDrop.Layout.Column = [2 4];
            
            app.PIDPCheck = uicheckbox(gl, 'Text', 'P', 'Value', true, 'ValueChangedFcn', @(~,~) app.onPIDCheckboxChanged());
            app.PIDPCheck.Layout.Row = 6; app.PIDPCheck.Layout.Column = 1;
            app.PIDICheck = uicheckbox(gl, 'Text', 'I', 'Value', true, 'ValueChangedFcn', @(~,~) app.onPIDCheckboxChanged());
            app.PIDICheck.Layout.Row = 6; app.PIDICheck.Layout.Column = 2;
            app.PIDDCheck = uicheckbox(gl, 'Text', 'D', 'Value', true, 'ValueChangedFcn', @(~,~) app.onPIDCheckboxChanged());
            app.PIDDCheck.Layout.Row = 6; app.PIDDCheck.Layout.Column = 3;
            
            lblKp = uilabel(gl, 'Text', 'Kp'); lblKp.Layout.Row = 7;
            app.PIDKpSlider = uislider(gl, 'Limits', [0 50], 'Value', 5, 'ValueChangedFcn', @(~,~) app.syncPIDSliderToEdit('Kp'));
            app.PIDKpSlider.Layout.Row = 7; app.PIDKpSlider.Layout.Column = [2 3];
            app.PIDKpEdit = uieditfield(gl, 'numeric', 'Value', 5, 'ValueChangedFcn', @(~,~) app.syncPIDEditToSlider('Kp'));
            app.PIDKpEdit.Layout.Row = 7; app.PIDKpEdit.Layout.Column = 4;
            
            lblKi = uilabel(gl, 'Text', 'Ki'); lblKi.Layout.Row = 8;
            app.PIDKiSlider = uislider(gl, 'Limits', [0 50], 'Value', 2, 'ValueChangedFcn', @(~,~) app.syncPIDSliderToEdit('Ki'));
            app.PIDKiSlider.Layout.Row = 8; app.PIDKiSlider.Layout.Column = [2 3];
            app.PIDKiEdit = uieditfield(gl, 'numeric', 'Value', 2, 'ValueChangedFcn', @(~,~) app.syncPIDEditToSlider('Ki'));
            app.PIDKiEdit.Layout.Row = 8; app.PIDKiEdit.Layout.Column = 4;
            
            lblKd = uilabel(gl, 'Text', 'Kd'); lblKd.Layout.Row = 9;
            app.PIDKdSlider = uislider(gl, 'Limits', [0 20], 'Value', 0.5, 'ValueChangedFcn', @(~,~) app.syncPIDSliderToEdit('Kd'));
            app.PIDKdSlider.Layout.Row = 9; app.PIDKdSlider.Layout.Column = [2 3];
            app.PIDKdEdit = uieditfield(gl, 'numeric', 'Value', 0.5, 'ValueChangedFcn', @(~,~) app.syncPIDEditToSlider('Kd'));
            app.PIDKdEdit.Layout.Row = 9; app.PIDKdEdit.Layout.Column = 4;
            
            lDist = uilabel(gl, 'Text', 'GANGGUAN (DISTURBANCE)', 'FontWeight', 'bold', 'FontColor', [0.09 0.49 0.52]);
            lDist.Layout.Row = 10; lDist.Layout.Column = [1 4];
            
            app.PIDDistCheck = uicheckbox(gl, 'Text', 'Aktifkan disturbance (step di input plant)', 'Value', true, ...
                'ValueChangedFcn', @(~,~) app.simulatePID(false));
            app.PIDDistCheck.Layout.Row = 11; app.PIDDistCheck.Layout.Column = [1 4];
            
            lblMag = uilabel(gl, 'Text', 'Magnitudo'); lblMag.Layout.Row = 12;
            app.PIDDistMagEdit = uieditfield(gl, 'numeric', 'Value', 0.5);
            app.PIDDistMagEdit.Layout.Row = 12; app.PIDDistMagEdit.Layout.Column = [2 4];
            
            lblTime = uilabel(gl, 'Text', 'Waktu (s)'); lblTime.Layout.Row = 13;
            app.PIDDistTimeEdit = uieditfield(gl, 'numeric', 'Value', 5);
            app.PIDDistTimeEdit.Layout.Row = 13; app.PIDDistTimeEdit.Layout.Column = [2 4];
            
            bSim = uibutton(gl, 'Text', 'Simulasikan & Catat', 'BackgroundColor', [0.09 0.49 0.52], ...
                'FontColor', [1 1 1], 'FontWeight', 'bold', 'ButtonPushedFcn', @(~,~) app.simulatePID(true));
            bSim.Layout.Row = 14; bSim.Layout.Column = [1 2];
            
            bRst = uibutton(gl, 'Text', 'Reset parameter', 'ButtonPushedFcn', @(~,~) app.resetPID());
            bRst.Layout.Row = 14; bRst.Layout.Column = [3 4];
            
            rightP = uipanel(g, 'BackgroundColor', [1 1 1]);
            rightP.Layout.Row = 2; rightP.Layout.Column = 2;
            gr = uigridlayout(rightP, [3 2]);
            gr.RowHeight = {'1.25x', 135, 130};
            gr.ColumnWidth = {'1x', '1x'};
            
            app.PIDStepAxes = uiaxes(gr); app.PIDStepAxes.Layout.Row = 1; app.PIDStepAxes.Layout.Column = 1;
            app.PIDDistAxes = uiaxes(gr); app.PIDDistAxes.Layout.Row = 1; app.PIDDistAxes.Layout.Column = 2;
            
            app.PIDMetricTable = uitable(gr, 'ColumnName', {'Parameter', 'Tanpa Pengendali', 'Dengan Pengendali'}, ...
                'RowName', {});
            app.PIDMetricTable.Layout.Row = 2; app.PIDMetricTable.Layout.Column = 1;
            
            app.PIDSummaryArea = uitextarea(gr, 'Editable', 'off', 'FontName', 'Consolas', 'FontSize', 11);
            app.PIDSummaryArea.Layout.Row = 2; app.PIDSummaryArea.Layout.Column = 2;
            
            app.PIDLogTable = uitable(gr, 'ColumnName', {'No', 'Config', 'Kp', 'Ki', 'Kd', 'Tr (s)', 'Ts (s)', 'Tp (s)', 'OS (%)', 'Ess'}, ...
                'RowName', {}, 'Data', cell(0, 10));
            app.PIDLogTable.Layout.Row = 3; app.PIDLogTable.Layout.Column = [1 2];
        end

        function buildBlackBoxUI(app)
            app.BlackBoxPanel = uipanel(app.MainGrid, 'BackgroundColor', [0.95 0.96 0.98], 'BorderType', 'none');
            app.BlackBoxPanel.Layout.Row = 1; app.BlackBoxPanel.Layout.Column = 1;
            
            g = uigridlayout(app.BlackBoxPanel, [2 2]);
            g.RowHeight = {46, '1x'};
            g.ColumnWidth = {320, '1x'};
            app.createTopBar(g, 'Black Box Control System (Bonus)');
            
            leftP = uipanel(g, 'BackgroundColor', [1 1 1]);
            leftP.Layout.Row = 2; leftP.Layout.Column = 1;
            gl = uigridlayout(leftP, [6 1]);
            gl.RowHeight = {38, 38, 80, 24, 42, '1x'};
            
            bLoad = uibutton(gl, 'Text', 'Muat data (CSV: t, u, y)', 'ButtonPushedFcn', @(~,~) app.loadBlackBoxCSV());
            bLoad.Layout.Row = 1;
            
            bDemo = uibutton(gl, 'Text', 'Gunakan data demo', 'ButtonPushedFcn', @(~,~) app.loadBlackBoxDemo());
            bDemo.Layout.Row = 2;
            
            app.BBInfoLabel = uilabel(gl, 'Text', 'Belum ada data dimuat.', 'WordWrap', 'on', 'FontSize', 11.5);
            app.BBInfoLabel.Layout.Row = 3;
            
            lId = uilabel(gl, 'Text', 'IDENTIFIKASI', 'FontWeight', 'bold', 'FontColor', [0.09 0.49 0.52]);
            lId.Layout.Row = 4;
            
            bId = uibutton(gl, 'Text', 'Identifikasi sistem', 'BackgroundColor', [0.09 0.49 0.52], ...
                'FontColor', [1 1 1], 'FontWeight', 'bold', 'ButtonPushedFcn', @(~,~) app.runBlackBoxIdentification());
            bId.Layout.Row = 5;
            
            desc = uilabel(gl, 'Text', ['Asumsi: input berupa STEP. Metode: ukur gain statis K, overshoot Mp, t28.3% dan t63.2%, ' ...
                'tentukan orde, bangun 4 model kandidat (Orde-1, Orde-1+delay, Orde-2, Orde-2+delay), bandingkan RMSE dan Fit%, ' ...
                'lalu pilih model paling sederhana dengan kecocokan terbaik (prinsip parsimoni).'], ...
                'WordWrap', 'on', 'VerticalAlignment', 'top', 'FontSize', 11, 'FontColor', [0.35 0.35 0.35]);
            desc.Layout.Row = 6;
            
            rightP = uipanel(g, 'BackgroundColor', [1 1 1]);
            rightP.Layout.Row = 2; rightP.Layout.Column = 2;
            gr = uigridlayout(rightP, [3 1]);
            gr.RowHeight = {'1.2x', 120, '1x'};
            
            app.BBAxes = uiaxes(gr); app.BBAxes.Layout.Row = 1;
            app.BBModelTable = uitable(gr, 'ColumnName', {'Model', 'Orde', 'RMSE', 'Fit (%)', 'Fungsi alih'}, ...
                'ColumnWidth', {160, 55, 80, 75, 'auto'}, 'RowName', {});
            app.BBModelTable.Layout.Row = 2;
            app.BBStepsArea = uitextarea(gr, 'Editable', 'off', 'FontName', 'Consolas', 'FontSize', 11.5);
            app.BBStepsArea.Layout.Row = 3;
        end

        function buildProfileUI(app)
            app.ProfilePanel = uipanel(app.MainGrid, 'BackgroundColor', [0.95 0.96 0.98], 'BorderType', 'none');
            app.ProfilePanel.Layout.Row = 1; app.ProfilePanel.Layout.Column = 1;
            
            g = uigridlayout(app.ProfilePanel, [2 2]);
            g.RowHeight = {46, '1x'};
            g.ColumnWidth = {320, '1x'};
            app.createTopBar(g, 'Developer Profile');
            
            leftP = uipanel(g, 'BackgroundColor', [1 1 1]);
            leftP.Layout.Row = 2; leftP.Layout.Column = 1;
            gl = uigridlayout(leftP, [2 1]);
            gl.RowHeight = {320, '1x'};
            gl.Padding = [20 20 20 20];
            
            app.ProfImage = uiimage(gl);
            app.ProfImage.Layout.Row = 1;
            imgCandidates = {'foto_profil.jpg', 'foto_profil.jpeg', 'foto_profil.png'};
            for idxImg = 1:numel(imgCandidates)
                imgPath = fullfile(pwd, 'assets', imgCandidates{idxImg});
                if exist(imgPath, 'file')
                    app.ProfImage.ImageSource = imgPath;
                    break;
                end
            end
            
            lblFoto = uilabel(gl, 'Text', 'Foto profil dimuat dari folder assets/', ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontColor', [0.4 0.4 0.4]);
            lblFoto.Layout.Row = 2;
            
            rightP = uipanel(g, 'BackgroundColor', [1 1 1]);
            rightP.Layout.Row = 2; rightP.Layout.Column = 2;
            gr = uigridlayout(rightP, [10 1]);
            gr.RowHeight = {22, 32, 22, 32, 22, 32, 22, 32, 26, '1x'};
            gr.Padding = [25 20 25 20];
            
            lblP1 = uilabel(gr, 'Text', 'Nama Lengkap', 'FontWeight', 'bold', 'FontColor', [0.09 0.49 0.52]); lblP1.Layout.Row = 1;
            app.ProfNameEdit = uieditfield(gr, 'text', 'Value', 'Ezra Putra Karuniawan'); app.ProfNameEdit.Layout.Row = 2;
            
            lblP2 = uilabel(gr, 'Text', 'NIM', 'FontWeight', 'bold', 'FontColor', [0.09 0.49 0.52]); lblP2.Layout.Row = 3;
            app.ProfNIMEdit = uieditfield(gr, 'text', 'Value', '612024008'); app.ProfNIMEdit.Layout.Row = 4;
            
            lblP3 = uilabel(gr, 'Text', 'Program Studi', 'FontWeight', 'bold', 'FontColor', [0.09 0.49 0.52]); lblP3.Layout.Row = 5;
            app.ProfProdiEdit = uieditfield(gr, 'text', 'Value', 'Teknik Elektro'); app.ProfProdiEdit.Layout.Row = 6;
            
            lblP4 = uilabel(gr, 'Text', 'Angkatan', 'FontWeight', 'bold', 'FontColor', [0.09 0.49 0.52]); lblP4.Layout.Row = 7;
            app.ProfAngkatanEdit = uieditfield(gr, 'text', 'Value', '2024'); app.ProfAngkatanEdit.Layout.Row = 8;
            
            lblP5 = uilabel(gr, 'Text', 'Pesan dan Kesan selama Praktikum Sistem Kendali 1', 'FontWeight', 'bold', 'FontSize', 13); lblP5.Layout.Row = 9;
            app.ProfNoteArea = uitextarea(gr, 'Value', {
                'Praktikum Sistem Kendali 1 membantu saya memahami hubungan langsung antara posisi pole-zero, perubahan gain K pada Root Locus, serta pengaruh tuning parameter Kp, Ki, dan Kd terhadap respons transien dan kestabilan sistem.'
            });
            app.ProfNoteArea.Layout.Row = 10;
        end
    end

    methods (Access = public)
        function app = ControlEngineeringLab
            createComponents(app);
            registerApp(app, app.UIFigure);
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.UIFigure);
        end
    end
end
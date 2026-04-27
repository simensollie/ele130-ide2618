%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% P05_ManuellKjoring
%
% Hensikten med programmet er å kjøre LEGO-roboten manuelt med
% styrestikken langs en grålinje på banen, og samle inn målinger
% slik at vi kan beregne kvalitetsmål for kjøringen (MAE, IAE, TV).
%
% Følgende sensorer brukes:
% - Lyssensor (måler reflektert lys, gir posisjon yk)
% - Gyrosensor (måler vinkelen til roboten)
%
% Følgende motorer brukes:
% - motor A (høyre hjul, koblet til EV3-port C)
% - motor B (venstre hjul, koblet til EV3-port B)
% Navnene "motor A" og "motor B" følger notasjonen i kapittel 9
% (u_A, u_B, TV_A, TV_B); selve EV3-portene er B og C i vårt oppsett.
%
% Kilder og referanser:
% - Oppgaven/teorien: Del-III_Kap9_Manuell_kjoring.pdf, kapittel 9.
%     * Kode 9.1 (s.88):  y(k)=Lys(k), r(k)=Lys(1), e(k)=r(k)-y(k)
%     * Lign. (9.2):      MAE_k rekursivt
%     * Lign. (9.3):      IAE med numerisk integrasjon (trapesmetoden)
%     * Lign. (9.8)-(9.9):TV_A,k og TV_B,k rekursivt
%     * Lign. (9.10)-(9.11): middelverdi og standardavvik etter kjøring
%     * Subplot-oppsett (4x2) er hentet fra figur 9.7 i kap. 9.3
% - Skjelett (clear/close, online-flagg, while-løkke med GET MEAS /
%   CONDITIONS / PLOT, JoyMainSwitch, drawnow): kopiert og forenklet fra
%   Prosjekt0X_BeskrivendeTekst/P0X_BeskrivendeTekst.m (= Vedlegg A.6
%   "Prosjektmal MATLAB").
% - Figur-posisjonering og struktur på avslutningsdel: inspirert av
%   Prosjekt04_PID_Regulering/PID_regulator/P04_PID.m
% - Trapesmetoden for IAE: gjenbruker formelen fra
%   MineFunksjoner/TrapesIntegrasjon.m (skrevet ut på rekursiv form her).
% - Lesing av joystick: bruker funksjonen Joystick/HentJoystickVerdier.m,
%   som også snur fortegnet på akse 2 slik at positivt = forover.
%
%--------------------------------------------------------------------------


%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%         EXPERIMENT SETUP, FILENAME AND FIGURE

clear; close all   % rydd workspace først
online   = false;   % true = mot EV3, false = bruk lagret datafil
plotting = true;   % false gir flest målinger, anbefales for endelig kjøring
filename = 'kjoring3-simen.mat';

if online
    % Kobler opp LEGO og styrestikke
    mylego   = legoev3('USB');
    joystick = vrjoystick(1);
    [JoyAxes, JoyButtons] = HentJoystickVerdier(joystick);

    % Sensorer som brukes i dette prosjektet
    myColorSensor = colorSensor(mylego);
    myGyroSensor  = gyroSensor(mylego);
    resetRotationAngle(myGyroSensor);   % nullstiller gyro før start

    % Motorer (motor A = høyre hjul = port C, motor B = venstre hjul = port B)
    motorA = motor(mylego,'C');
    motorA.resetRotation;
    motorB = motor(mylego,'B');
    motorB.resetRotation;
    start(motorA);
    start(motorB);
else
    % Hvis online=false leses tidligere lagret data fra fil.
    % NB: load() overskriver workspace-variabler med samme navn som finnes
    % i .mat-filen, så vi setter kontrollflaggene på nytt etter load.
    saved_plotting = plotting;
    load(filename)
    online   = false;
    plotting = saved_plotting;
    clear saved_plotting
end

% Lager en høy figur slik at det er plass til 4x2 subplots
fig1 = figure;
set(fig1, 'Position', [200 50 700 850])
drawnow

% Skyteknapp på styrestikken (knapp 1) brukes for å stoppe forsøket
JoyMainSwitch = 0;
k = 0;

% Skalerer ned joystick-utslaget slik at roboten ikke blir hakkete
skalering_forover = 0.5;
skalering_sving   = 0.3;

% Hvis lysmålingen blir veldig høy betyr det at sensoren er på hvitt,
% og da skal programmet stoppe siden vi har kjørt ut av banen.
hvit_grense = 80;

MAX_SPEED = 300;
%----------------------------------------------------------------------



while ~JoyMainSwitch
    %+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    %                       GET TIME AND MEASUREMENT
    % Hent tid og målinger fra sensorer, motorer og styrestikke

    k = k + 1;   % øker tellevariabelen for hvert tidsskritt

    if online
        if k == 1
            % Lyd som forteller meg at innsamlingen har startet
            playTone(mylego, 500, 0.1)
            tic           % starter stoppeklokke
            t(1) = 0;
        else
            t(k) = toc;   % tid siden start
        end

        % Sensormålinger
        Lys(k)       = double(readLightIntensity(myColorSensor,'reflected'));
        GyroAngle(k) = double(readRotationAngle(myGyroSensor));

        % Henter ut joystick-verdier
        [JoyAxes, JoyButtons] = HentJoystickVerdier(joystick);
        JoyMainSwitch  = JoyButtons(1);   % skyteknapp stopper forsøket
        JoyForover(k)  = JoyAxes(2);      % positivt = forover
        JoySideveis(k) = JoyAxes(1);      % positivt = høyre
    else
        % Når k når antall lagrede målinger, simulerer vi at
        % skyteknappen blir trykket inn slik at løkka stopper.
        if k == length(t)
            JoyMainSwitch = 1;
        end
        if plotting
            pause(0.03)   % simulerer kommunikasjonstid mot EV3
        end
    end
    %--------------------------------------------------------------



    %+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    %             CONDITIONS, CALCULATIONS AND SET MOTOR POWER

    % Lysmålingen er utgangen fra prosessen, dvs. y(k)
    y(k) = Lys(k);

    if k == 1
        % Referansen settes til den første lysmålingen,
        % og den holdes konstant gjennom hele kjøringen.
        r(1) = Lys(1);
        e(1) = r(1) - y(1);   % blir 0 ved første måling

        % Tidsskritt finnes ikke ved første måling
        Ts(1) = 0;

        % Initialverdier for kvalitetsmålene
        MAE(1)  = 0;
        IAE(1)  = 0;
        TV_A(1) = 0;
        TV_B(1) = 0;

        % Motorpådrag starter på 0
        u_A(1) = 0;
        u_B(1) = 0;
    else
        % Tidsskritt mellom forrige og nåværende måling
        Ts(k) = t(k) - t(k-1);

        % Referansen er konstant lik første lysmåling
        r(k) = r(1);

        % Reguleringsavviket er forskjellen mellom referanse og måling
        e(k) = r(k) - y(k);

        % MAE rekursivt: nytt snitt regnes ut fra forrige snitt + nytt |e|
        MAE(k) = (MAE(k-1)*(k-1) + abs(e(k))) / k;

        % IAE rekursivt med trapesmetoden:
        % areal under |e| på siste tidsskritt legges til forrige IAE
        IAE(k) = IAE(k-1) + Ts(k)*( abs(e(k-1)) + abs(e(k)) )/2;

        % Beregner motorpådrag fra joystick.
        % motor A og B kombineres slik at roboten går rett frem
        % når JoySideveis=0, og svinger når JoySideveis er ulik 0.
        u_A(k) = skalering_forover*JoyForover(k) - skalering_sving*JoySideveis(k);
        u_B(k) = skalering_forover*JoyForover(k) + skalering_sving*JoySideveis(k);

        % TV rekursivt: legg til endringen i pådrag siden forrige tidsskritt
        TV_A(k) = TV_A(k-1) + abs(u_A(k) - u_A(k-1));
        TV_B(k) = TV_B(k-1) + abs(u_B(k) - u_B(k-1));
    end

    % Hvis lyssensoren havner på det hvite (utenfor banen) skal
    % programmet stoppe, og vi må starte på nytt.
    if y(k) > hvit_grense
        disp('Lyssensoren er på hvitt. Stopper programmet.')
        JoyMainSwitch = 1;
    end

    if online
        % Sender pådragsverdier til motorene
        motorA.Speed = u_A(k);
        motorB.Speed = u_B(k);
        %start(motorA)
        %start(motorB)
    end
    %--------------------------------------------------------------



    %++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    %                  PLOT DATA
    % Plotter enten i sann tid (plotting=true) eller når
    % forsøket avsluttes (JoyMainSwitch=1).

    if plotting || JoyMainSwitch
        figure(fig1)

        % subplot(4,2,1): gyrosensor
        subplot(4,2,1)
        plot(t(1:k), GyroAngle(1:k), 'b-')
        grid on
        title('Vinkelm{\aa}ling, gyrosensor')
        ylabel('[$^{\circ}$]')

        % subplot(4,2,2): lysmåling og referanse
        subplot(4,2,2)
        plot(t(1:k), y(1:k), 'b-'); hold on
        plot(t(1:k), r(1:k), 'r-'); hold off
        grid on
        title('Lysm{\aa}ling og referanse')
        legend('$\{y_k\}$','$\{r_k\}$')

        % subplot(4,2,3): reguleringsavvik
        subplot(4,2,3)
        plot(t(1:k), e(1:k), 'b-')
        grid on
        title('Reguleringsavvik')
        legend('$\{e_k\}$')

        % subplot(4,2,4): motorpådrag
        subplot(4,2,4)
        plot(t(1:k), u_A(1:k), 'b-'); hold on
        plot(t(1:k), u_B(1:k), 'r-'); hold off
        grid on
        title('P{\aa}drag motor A og B')
        legend('$\{u_{A,k}\}$','$\{u_{B,k}\}$')

        % subplot(4,2,5): IAE
        subplot(4,2,5)
        plot(t(1:k), IAE(1:k), 'b-')
        grid on
        title('Integral of absolute error')
        legend('$\{IAE_k\}$')

        % subplot(4,2,6): TV for motor A og B
        subplot(4,2,6)
        plot(t(1:k), TV_A(1:k), 'b-'); hold on
        plot(t(1:k), TV_B(1:k), 'r-'); hold off
        grid on
        title('Total variation')
        legend('$\{TV_{A,k}\}$','$\{TV_{B,k}\}$')

        % subplot(4,2,7): MAE
        subplot(4,2,7)
        plot(t(1:k), MAE(1:k), 'b-')
        grid on
        title('Mean of absolute error')
        legend('$\{MAE_k\}$')
        xlabel('Tid [sek]')

        % subplot(4,2,8): samplingstiden Ts
        subplot(4,2,8)
        if k > 1
            plot(t(2:k), Ts(2:k), 'b.-')
            title(['Tidsskritt $T_s$. Gj.snitt=', ...
                num2str(mean(Ts(2:k)),'%.3f'), ' s.'])
        end
        grid on
        ylabel('[s]')
        xlabel('Tid [sek]')

        drawnow
    end
    %--------------------------------------------------------------
end


%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%               STOP MOTORS
if online
    stop(motorA);
    stop(motorB);
end
%------------------------------------------------------------------


%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%               KVALITETSMÅL ETTER KJØRING (y_bar, sigma)
%
% Etter kjøringen beregnes middelverdi og standardavvik
% for lysmålingene. Disse sier noe om hvor vinglete vi har kjørt.

y_bar = mean(y);
sigma = std(y);

fprintf('\n--- Sluttresultater ---\n');
fprintf('Referanse  r       = %.2f\n', r(1));
fprintf('Middelverdi y_bar  = %.2f\n', y_bar);
fprintf('Standardavvik sigma= %.2f\n', sigma);
fprintf('IAE                = %.2f\n', IAE(end));
fprintf('MAE                = %.2f\n', MAE(end));
fprintf('TV_A               = %.2f\n', TV_A(end));
fprintf('TV_B               = %.2f\n', TV_B(end));
fprintf('Gj.snitt Ts [s]    = %.3f\n', mean(Ts(2:end)));
fprintf('Kjøretid [s]       = %.2f\n', t(end));
fprintf('Antall målinger    = %d\n',   k);
%------------------------------------------------------------------

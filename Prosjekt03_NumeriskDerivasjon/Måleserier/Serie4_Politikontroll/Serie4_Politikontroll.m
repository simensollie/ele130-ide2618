% Numerisk derivasjon av avstandsmåling
clear; close all
load('Serie4_Rampe.mat')
x = Lys;  % posisjon [m]

%FrekvensSpekter(t, x);
fc = 0.3;
tau = 1/(2*pi*fc);

% Lavpassfiltrerte avstandsmåling (to filtre i serie)
x_f1 = LavpassFilter(t, x, tau=tau/2);
x_f2  = LavpassFilter(t, x_f1, tau=tau/2);

% Beregnede hastigheten som er den deriverte av signalet/målingene
v = BakoverDerivasjon(t, x);

% Regner ut gjennomsnittsfarten mellom 5 og 10 sekunder
idx = t >= 5 & t <= 10; % Plukker ut alle indekser mellom 5 og 10 sekund
v_snitt = mean(v(idx)); % Regner ut snitt av farten i alle utplukkede indekser

% Beregnede hastigheten som er den deriverte av det filtrerte avstanden
v_f = BakoverDerivasjon(t, x_f2);

% Sammenligning av filtreringene
figure
subplot(3,1,1)
plot(t, x, 'b', t, x_f2, 'r')
grid on
legend('M\aa ling $\{x_k\}$', 'Filtrert m\aa ling $\{x_{f,k}\}$', 'Location', 'best')
ylabel('[m]')
title('Avstandsm\aa ling')

subplot(3,1,2)
plot(t, v, 'b')
grid on
ylim([-inf 0])
legend('Hastighet $\{v_k\}$', 'Location', 'best')
ylabel('[m/s]')
title('Beregnet hastighet fra selve m\aa ling')

subplot(3,1,3)
plot(t, v_f, 'r')
hold on
yline(v_snitt, 'k--')
grid on
ylim([-inf 0])
legend('Hastighet $\{v_{f,k}\}$', 'Gjennomsnittshastighet $\bar{v}$', 'Location', 'best')
ylabel('[m/s]')
title('Beregnet hastighet fra filtrert m\aa ling')
xlabel('tid [s]')

% Verifisering: beregn gjennomsnittsfart fra filtrert posisjon
v_verif = (15.5 - 39.8) / (10 - 5);
fprintf('Verifisering: v_snitt = (15.5 - 39.8) / (10 - 5) = %.1f m/s\n', v_verif)

% Måling av temperatur med termometer
clear; close all
load('Serie1_Sprang.mat')
T = Lys;  % temperatur i det kalde og varme vannet

% Estimert tidskonstant fra video
tau = 7; % t_0 = 32s, t_63 = 39s
T_f = LavpassFilter(t, T, IC=T(1), tau=tau);

% Finn tidspunktet for spranget i målingen
T_start = T(1);                         
T_slutt = T(end);
T_tau = T_start + 0.632*(T_slutt - T_start);  % 63.2% av spranget

% Finn tidspunktet der data stiger over 50%
idx_sprang = find(T > (T_start + T_slutt)/2, 1); % indeks
t_sprang = t(idx_sprang); % tidspunkt

% Finn tidspunktet der filteret når 63.2%-verdien
idx_tau = find(T_f >= T_tau, 1);
t_tau = t(idx_tau);

% Plotting
figure
plot(t, T, 'b-')
hold on
plot(t, T_f, 'r-', 'LineWidth', 1.5)

% Marker tau-punktet
plot(t_tau, T_tau, 'ko', 'MarkerSize', 4, 'MarkerFaceColor', 'k')
xline(t_sprang, 'k--') % sort stiplet
xline(t_tau, 'r--') % rød stiplet

hold off
grid on
title('Termometer')
xlabel('tid')
ylabel('temperatur')
legend('Målt temperatur T_k', ...
       ['Filtrert (termometer), \tau = ', num2str(tau), ' s'], ...
       'Avlest \tau-punkt (63.2%)', ...
       'Location', 'best')
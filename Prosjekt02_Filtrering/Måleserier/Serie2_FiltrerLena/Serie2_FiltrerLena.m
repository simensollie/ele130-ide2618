% Filtrering av pixelstripe fra bilde av Lena
clear; close all
load('Serie2_Bilde.mat')
u = Lys;  % intensitetsprofilen i bilde

% FrekvensSpekter(t, u);

fc = 0.8;
tau = 1/(2*pi*fc);

% Lavpassfiltrering i 1. orden
u_f = LavpassFilter(t, u, tau=tau);

% Lavpassfiltrering i 3. orden
u1_f = LavpassFilter(t, u,    tau=tau/3);   % 1. orden
u2_f = LavpassFilter(t, u1_f, tau=tau/3);   % 2. orden
u3_f = LavpassFilter(t, u2_f, tau=tau/3);   % 3. orden

% Sammenligning av filtreringene
figure
plot(t, u, 'b', t, u_f, 'r', t, u3_f, 'g')
grid on
legend('$\{u_k\}$', '$\{u_{f,k}\}$', '$\{u_{3f,k}\}$')
title('Filtrering av intensitetsprofil i bilde')
xlabel('tid [s]')
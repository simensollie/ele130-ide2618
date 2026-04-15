% Numerisk derivasjon av posisjonsmålingene 
% til masse-fjær-system
clear; close all
load('Serie5_Sinus_u20.mat')
x = Lys;   % posisjon

%plot(t,x,'.');
%plot(x,'.');

% Estimerer startindeks k0 for sinus
t0 = 3.1;
k0 = find(t >= t0, 1); 
fprintf('Første indeks for sinuskurve: %d\n', k0);
% Finner indeks både ved å lese av tidspunkt og deretter finne første 
% indeks etter dette tidspunktet. Bekreftet ved å lese av indeks 
% direkte fra figuren.

% Fjerner all indeks/punkter før k0
x_vasket = x(k0:end);
t_vasket = t(k0:end);

% Ingen uteliggere observert i figur, bruker isoutlier() for å bekrefte
% Testet med 'mean', 'median', 'movmean, 5' og 'movmedian, 5'. 
% Alle ga 0 utenom sistnevnte. Den ga 3 uteliggere som anses som ubetydelig.
TF = isoutlier(x_vasket, 'movmedian', 5);
fprintf('Antall uteliggere: %d av %d\n', sum(TF), numel(x_vasket));
% Ref: https://se.mathworks.com/help/matlab/ref/isoutlier.html

%FrekvensSpekter(t_vasket, x_vasket, fmax=4);
fc = 1.6;

% Først finne fart og deretter filtrere
v = BakoverDerivasjon(t_vasket, x_vasket);
v_1f = LavpassFilter(t_vasket, v, fc=fc);

% Først filtrere signal og deretter finne fart
x_f = LavpassFilter(t_vasket, x_vasket, fc=fc);
v_2f = BakoverDerivasjon(t_vasket, x_f);

% Plots
figure
ax1 = subplot(2,2,1);
plot(t_vasket, x_vasket, 'k')
grid on
ylabel('[m]')
title('M\aa ling av avstand')

ax2 = subplot(2,2,2);
plot(t_vasket, v, 'b')
grid on
ylabel('[m/s]')
title('Fart (uten filter)')

ax3 = subplot(2,2,3);
plot(t_vasket, x_f, 'r')
grid on
ylabel('[m]')
xlabel('tid [s]')
title('Filtrert avstand')

ax4 = subplot(2,2,4);
plot(t_vasket, v_1f, 'b', t_vasket, v_2f, 'r')
grid on
ylabel('[m/s]')
xlabel('tid [s]')
title('Estimat av fart')
legend({'Derivert \rightarrow filtrert', ...
        'Filtrert \rightarrow derivert'}, ...
       'Interpreter', 'tex', 'Location', 'best')

% Felles y-akse per kolonne for å gjøre før/etter-filter sammenlignbart
% Ref: https://se.mathworks.com/help/matlab/ref/linkaxes.html
linkaxes([ax1 ax3], 'y')           % avstand [m]
linkaxes([ax2 ax4], 'y')           % fart [m/s]
linkaxes([ax1 ax2 ax3 ax4], 'x')   % felles tidsakse

% Rekkefølgen har ikke noe å si
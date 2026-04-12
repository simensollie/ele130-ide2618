% Pumpe vann (med luftbobler) inn og ut av ballong som en sinus-strømning
clear; close all
load('Serie6_SinusStoy_u20.mat')
q = Lys;       % volumstrøm inn og ut av ballong [cl/s]

% Sentrering av sinuskurve rundt 0
amplitude = (max(q) + min(q)) / 2;
q_sentrert = q - amplitude;

% Frekvensspekter for å identifisere knekkpunkt for filtre
FrekvensSpekter(t, q_sentrert);

% 6.2.1 Lavpassfiltrering
LavpassFilter(t, q_sentrert, fc=1.0);

% 6.2.2 Høypassfiltrering
HoypassFilter(t, q_sentrert, fc=1.4);

%% Dokumentasjon med IIRfilter
% Regner ut gjennomsnittet av tiden mellom målingene (tidsskritt)
Ts = mean(diff(t));

% Lavpass (fc = 1.0 Hz)
% Regner ut tidskonstanten for gitt knekkfrekvens
fc_lp = 1.0;
tau_lp = 1/(2*pi*fc_lp);              % LavpassFilter.m linje 39
% Parameter for første ordens lavpassfilter
alfa = 1 - exp(-Ts/tau_lp);           % LavpassFilter.m linje 52
% IIRfilter(tid, signal, B, A, fc, fmax)
IIRfilter(t, q_sentrert, [alfa], [1, -(1-alfa)], fc=fc_lp, fmax=5)  % LavpassFilter.m linje 53

% Høypass (fc = 1.4 Hz)
% Regner ut tidskonstanten for gitt knekkfrekvens
fc_hp = 1.4;
tau_hp = 1/(2*pi*fc_hp);              % HoypassFilter.m linje 39
% Parameter for første ordens høypassfilter
betta = exp(-Ts/tau_hp);              % HoypassFilter.m linje 51
IIRfilter(t, q_sentrert, [betta, -betta], [1, -betta], fc=fc_hp, fmax=5)  % HoypassFilter.m linje 52
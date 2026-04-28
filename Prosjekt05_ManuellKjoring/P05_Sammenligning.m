% Sammenligner fordelingen av lysmålingene fra siste kjøring til hver
% av de tre gruppemedlemmene. Plottinga bruker teknikken fra øving 1e.

clear; close all;
% Filer og medlemsnavn
filer = { 'kjoring1-carsten.mat', ...
          'kjoring3-simen.mat',   ...
          'kjoring1-trygve.mat' };
navn  = { 'Carsten', 'Simen', 'Trygve' };
N = numel(filer);

% Last inn lysmålinger
Lys_alle = cell(N, 1);
for i = 1:N
    S = load(filer{i}, 'Lys');
    Lys_alle{i} = S.Lys;
end

% Felles akser og intervaller
Lys_samlet = [Lys_alle{:}];

max_x = ceil(max(Lys_samlet));   % bestemmer øverste grense for histogram
min_x = floor(min(Lys_samlet));  % bestemmer nederste grense for histogram
step  = 1;                       % bestemmer intervallbredden for histogram
edges = min_x:step:max_x;

% Finn høyeste søyle på tvers av medlemmene, slik at y-aksen blir lik
ymax = 0;
for i = 1:N
    h = histcounts(Lys_alle{i}, edges);
    if max(h) > ymax
        ymax = max(h);
    end
end
ymax = ymax + 2;

% Plot
figure(1)
set(gcf, 'units', 'normalized', 'outerposition', [0.3 0.02 0.35 0.95])

% Lag subplot per medlem
for i = 1:N
    Lys = Lys_alle{i};

    subplot(N, 1, i)
    h = histogram(Lys, edges);
    xline(mean(Lys), 'r', 'LineWidth', 2); % middelverdi som rød linje
    hold on
    std_hoyde = max(h.Values) / 3;
    plot([mean(Lys), mean(Lys)+std(Lys)], ...
         [std_hoyde, std_hoyde], ...
         'g', 'LineWidth', 2); % standardavvik som grønn linje

    grid on
    axis([min_x max_x 0 ymax]) % identiske akser

    title(navn{i})
    xlabel('Lysverdier')
    ylabel('antall m{\aa}linger')
    legend('Lys $\{y_k\}$', ...
        ['$\bar{y}=', num2str(mean(Lys), '%.1f'), '$'], ...
        ['$\sigma=', num2str(std(Lys), '%.1f'), '$'], ...
        'Location', 'northeast')
end

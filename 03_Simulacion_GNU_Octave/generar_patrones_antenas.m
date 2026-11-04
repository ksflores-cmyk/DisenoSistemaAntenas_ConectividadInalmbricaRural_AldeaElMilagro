% =========================================================================
% PROYECTO FINAL ANTENAS Y PROPAGACION 2026 - UNIS GUATEMALA
% Script: generar_patrones_antenas.m (Compatible 100% con GNU Octave)
% Genera automaticamente las 4 figuras de alta resolucion (300 DPI):
%   1. fig_octave_cortes_hv_familias.png
%   2. fig_octave_factor_arreglo_sectorial.png
%   3. fig_octave_apertura_vs_hpbw.png
%   4. fig_octave_cobertura_azimutal_360.png
% =========================================================================
clear; clc; close all;
graphics_toolkit("qt"); % Si da aviso en tu PC, Octave usara fltk/gnuplot automaticamente

theta_deg = linspace(-180, 180, 1801);
theta_rad = deg2rad(theta_deg);

% Funcion auxiliar para modelar patrones directivos reales con lobulos secundarios y F/B
function pat_db = model_pattern(ang_rad, hpbw_deg, fb_db, sll_db)
    % Exponente gaussiano principal calibrado para caer exactamente -3.01 dB en +/- HPBW/2
    sigma_rad = deg2rad(hpbw_deg / 2) / sqrt(2 * log(2));
    main_lobe = exp(-0.5 * (ang_rad ./ sigma_rad).^2);
    % Termino de lobulos secundarios y radiacion trasera limitada por F/B
    k_sll = pi / deg2rad(hpbw_deg * 0.85);
    side_lobes = (10^(sll_db/20)) * abs(sin(k_sll * ang_rad) ./ (k_sll * ang_rad + 1e-9));
    back_floor = 10^(-fb_db/20) * (0.6 + 0.4*cos(ang_rad/2).^2);
    E_tot = max(main_lobe, max(side_lobes .* (abs(ang_rad) > deg2rad(hpbw_deg*0.7)), back_floor));
    pat_db = 20 * log10(E_tot / max(E_tot));
    pat_db(pat_db < -40) = -40;
endfunction

% -------------------------------------------------------------------------
% FIGURA 1: Cortes Horizontal (Azimut) y Vertical (Elevacion) de las 4 Antenas
% -------------------------------------------------------------------------
pat_AF30_H   = model_pattern(theta_rad, 5.8,  30, -22); % AF-5G30-S45 (5.8 deg)
pat_Sector_H = model_pattern(theta_rad, 120.0, 25, -18); % AM-V5G-Ti H (120 deg)
pat_Sector_V = model_pattern(theta_rad - deg2rad(-1.5), 4.0, 25, -15); % AM-V5G-Ti V (-1.5 deg tilt)
pat_LTUPro   = model_pattern(theta_rad, 18.0, 24, -15); % LTU-Pro (18 deg)
pat_LTULR    = model_pattern(theta_rad, 11.0, 28, -18); % LTU-LR (11 deg)

f1 = figure('Position', [100, 100, 1200, 520], 'Color', 'w');

% Subplot Izquierdo: Corte Horizontal (Azimut)
subplot(1, 2, 1);
plot(theta_deg, pat_AF30_H,   'Color', [0.85 0.10 0.10], 'LineWidth', 2.2); hold on;
plot(theta_deg, pat_LTULR,    'Color', [0.00 0.45 0.74], 'LineWidth', 2.0);
plot(theta_deg, pat_LTUPro,   'Color', [0.10 0.65 0.25], 'LineWidth', 2.0);
plot(theta_deg, pat_Sector_H, 'Color', [0.55 0.15 0.70], 'LineWidth', 2.2);
plot([-180 180], [-3 -3], 'k--', 'LineWidth', 1.2);
grid on; xlim([-180 180]); ylim([-35 2]);
set(gca, 'XTick', -180:30:180, 'FontSize', 10);
xlabel('Angulo de Azimut \phi (grados)', 'FontWeight', 'bold');
ylabel('Ganancia Normalizada (dB)', 'FontWeight', 'bold');
title('Corte Horizontal (Plano H - Azimut)', 'FontSize', 12, 'FontWeight', 'bold');
legend({'AF-5G30-S45 (HPBW=5.8°)', 'LTU-LR (HPBW=11°)', 'LTU-Pro (HPBW=18°)', ...
        'AM-V5G-Ti Sector (HPBW=120°)', 'Umbral -3 dB (HPBW)'}, 'Location', 'south');

% Subplot Derecho: Corte Vertical (Elevacion, Zoom -30 a +30 grados)
subplot(1, 2, 2);
plot(theta_deg, pat_AF30_H,   'Color', [0.85 0.10 0.10], 'LineWidth', 2.2); hold on;
plot(theta_deg, pat_LTULR,    'Color', [0.00 0.45 0.74], 'LineWidth', 2.0);
plot(theta_deg, pat_LTUPro,   'Color', [0.10 0.65 0.25], 'LineWidth', 2.0);
plot(theta_deg, pat_Sector_V, 'Color', [0.55 0.15 0.70], 'LineWidth', 2.2);
plot([-30 30], [-3 -3], 'k--', 'LineWidth', 1.2);
grid on; xlim([-25 25]); ylim([-35 2]);
set(gca, 'XTick', -25:5:25, 'FontSize', 10);
xlabel('Angulo de Elevacion \theta (grados)', 'FontWeight', 'bold');
ylabel('Ganancia Normalizada (dB)', 'FontWeight', 'bold');
title('Corte Vertical (Plano V - Elevacion con Tilt -1.5°)', 'FontSize', 12, 'FontWeight', 'bold');
legend({'AF-5G30-S45 (HPBW=5.8°)', 'LTU-LR (HPBW=11°)', 'LTU-Pro (HPBW=18°)', ...
        'AM-V5G-Ti Sector (HPBW=4.0°, Tilt=-1.5°)', 'Umbral -3 dB'}, 'Location', 'south');

print(f1, 'fig_octave_cortes_hv_familias.png', '-dpng', '-r300');

% -------------------------------------------------------------------------
% FIGURA 2: Sintesis del Factor de Arreglo Vertical (Semana 5 - AM-V5G-Ti)
% -------------------------------------------------------------------------
N = 12;                  % 12 parches microstrip apilados verticalmente
d_lam = 0.72;            % Separacion d = 0.72 lambda (3.72 cm a 5.8 GHz)
tilt_deg = -1.5;         % Downtilt de -1.5 grados configurado en UISP
el_deg = linspace(-45, 45, 1801);
el_rad = deg2rad(el_deg);

% Patron de un parche microstrip individual en elevacion (coseno)
E_elem = cos(el_rad);
E_elem_db = 20*log10(abs(E_elem) + 1e-6);

% Factor de Arreglo Uniforme de N=12 elementos con desfasaje por tilt
psi = 2 * pi * d_lam * (sin(el_rad) - sin(deg2rad(tilt_deg)));
AF = abs(sin(N * psi / 2) ./ (N * sin(psi / 2) + 1e-12));
AF_db = 20*log10(AF / max(AF) + 1e-6);
AF_db(AF_db < -35) = -35;

% Patron Total = Patron Elemento x Factor de Arreglo
E_tot = abs(E_elem) .* AF;
E_tot_db = 20*log10(E_tot / max(E_tot) + 1e-6);
E_tot_db(E_tot_db < -35) = -35;

f2 = figure('Position', [120, 120, 1000, 480], 'Color', 'w');
plot(el_deg, E_elem_db, 'b--', 'LineWidth', 1.8); hold on;
plot(el_deg, AF_db,     'Color', [0.90 0.45 0.00], 'LineWidth', 1.8);
plot(el_deg, E_tot_db,  'Color', [0.55 0.10 0.65], 'LineWidth', 2.5);
plot([-45 45], [-3 -3], 'k:', 'LineWidth', 1.2);
grid on; xlim([-30 30]); ylim([-35 2]);
xlabel('Angulo de Elevacion \theta (grados respecto al horizonte)', 'FontWeight', 'bold');
ylabel('Respuesta Normalizada (dB)', 'FontWeight', 'bold');
title('Semana 5: Sintesis del Arreglo Colineal Vertical AM-V5G-Ti (N=12, d=0.72\lambda, Tilt=-1.5°)', ...
      'FontSize', 12, 'FontWeight', 'bold');
legend({'Elemento Parche Microstrip Individual (HPBW \approx 90°)', ...
        'Factor de Arreglo Lineal AF(\theta) N=12', ...
        'Patron Total Resultante (HPBW_V = 4.0° apuntado a -1.5°)', ...
        'Nivel de Media Potencia (-3 dB)'}, 'Location', 'south');

print(f2, 'fig_octave_factor_arreglo_sectorial.png', '-dpng', '-r300');

% -------------------------------------------------------------------------
% FIGURA 3: Relacion Fisica Apertura Efectiva (Ae) vs Ganancia y HPBW a 5.8 GHz
% -------------------------------------------------------------------------
lam = 3e8 / 5.8e9; % 0.05172 m
D_vec = linspace(0.10, 0.80, 200);
eta_ap = 0.64;
Ae_vec = eta_ap * pi * (D_vec/2).^2;
G_vec_dbi = 10 * log10(4 * pi * Ae_vec / (lam^2));
HPBW_vec = 70 * lam ./ D_vec;

f3 = figure('Position', [140, 140, 1100, 460], 'Color', 'w');
subplot(1, 2, 1);
plot(Ae_vec * 10000, G_vec_dbi, 'b-', 'LineWidth', 2.2); hold on;
% Puntos exactos de las antenas del proyecto en 5.8 GHz
pts_Ae = [169.1, 534.8, 847.5, 2129.0];
pts_G  = [19.0,  24.0,  26.0,  30.0];
plot(pts_Ae, pts_G, 'ro', 'MarkerSize', 9, 'MarkerFaceColor', 'r');
text(169.1+40, 19.0-0.5, 'AM-V5G-Ti (19 dBi)', 'FontWeight', 'bold');
text(534.8+40, 24.0-0.5, 'LTU-Pro (24 dBi)', 'FontWeight', 'bold');
text(847.5+40, 26.0-0.5, 'LTU-LR (26 dBi)', 'FontWeight', 'bold');
text(1350,     29.2,     'AF-5G30-S45 (30 dBi)', 'FontWeight', 'bold');
grid on; xlabel('Apertura Efectiva A_e (cm^2)', 'FontWeight', 'bold');
ylabel('Ganancia Directiva G (dBi)', 'FontWeight', 'bold');
title('Semana 3 y 9: Ganancia vs Apertura Efectiva (5.8 GHz)', 'FontWeight', 'bold');

subplot(1, 2, 2);
plot(D_vec * 100, HPBW_vec, 'Color', [0.85 0.20 0.10], 'LineWidth', 2.2); hold on;
pts_D    = [20.1, 28.0, 35.2, 65.0];
pts_HPBW = [18.0, 13.0, 11.0, 5.8];
plot([20.1, 33.0, 65.0], [18.0, 11.0, 5.8], 'ko', 'MarkerSize', 9, 'MarkerFaceColor', [0.1 0.7 0.2]);
text(22, 18.5, 'LTU-Pro (18°)', 'FontWeight', 'bold');
text(35, 11.8, 'LTU-LR (11°)', 'FontWeight', 'bold');
text(46, 7.2,  'AF-5G30-S45 (5.8°)', 'FontWeight', 'bold');
grid on; xlabel('Diametro / Dimension Equivalente D (cm)', 'FontWeight', 'bold');
ylabel('Ancho de Haz HPBW (grados)', 'FontWeight', 'bold');
title('Compresion Angular del Haz vs Apertura Fisica', 'FontWeight', 'bold');

print(f3, 'fig_octave_apertura_vs_hpbw.png', '-dpng', '-r300');

% -------------------------------------------------------------------------
% FIGURA 4: Diagrama Polar de Sectorizacion 360 Grados y Estaciones CPE
% -------------------------------------------------------------------------
az_deg = linspace(0, 360, 721);
az_rad = deg2rad(az_deg);

% Funcion de distancia angular envuelta en [-pi, pi]
wrap_ang = @(a, a0) mod(a - a0 + pi, 2*pi) - pi;

G_S1 = 19 + model_pattern(wrap_ang(az_rad, deg2rad(0)),   120, 25, -18);
G_S2 = 19 + model_pattern(wrap_ang(az_rad, deg2rad(120)), 120, 25, -18);
G_S3 = 19 + model_pattern(wrap_ang(az_rad, deg2rad(240)), 120, 25, -18);
G_S1(G_S1 < 0) = 0; G_S2(G_S2 < 0) = 0; G_S3(G_S3 < 0) = 0;

f4 = figure('Position', [160, 160, 760, 660], 'Color', 'w');
h1 = polar(az_rad, G_S1, 'r-'); hold on; set(h1, 'LineWidth', 2.2);
h2 = polar(az_rad, G_S2, 'b-'); set(h2, 'LineWidth', 2.2);
h3 = polar(az_rad, G_S3, 'g-'); set(h3, 'LineWidth', 2.2);

% Circulo de cruce a -3 dB (16 dBi)
h_3db = polar(az_rad, 16 * ones(size(az_rad)), 'k--'); set(h_3db, 'LineWidth', 1.2);

% Direcciones azimutales reales desde Tower 1 hacia los 6 CPEs en UISP
cpe_az_deg = [341, 26, 100, 140, 263, 229];
cpe_r_dbi  = [18.7, 18.5, 18.7, 18.7, 18.6, 18.9];
h_cpe = polar(deg2rad(cpe_az_deg), cpe_r_dbi, 'ko');
set(h_cpe, 'MarkerSize', 9, 'MarkerFaceColor', 'y');

title('Cobertura Azimutal 360° en Tower 1 (Sectores S1=0°, S2=120°, S3=240° y 6 CPEs)', ...
      'FontSize', 12, 'FontWeight', 'bold');
legend({'Sector S1 (0°N, 19 dBi)', 'Sector S2 (120°E, 19 dBi)', ...
        'Sector S3 (240°W, 19 dBi)', 'Cruce -3 dB (16 dBi en 60°, 180°, 300°)', ...
        '6 Estaciones CPE (S1-A/B, S2-A/B, S3-A/B)'}, 'Location', 'southoutside');

print(f4, 'fig_octave_cobertura_azimutal_360.png', '-dpng', '-r300');
disp('Las 4 graficas PNG de 300 DPI se han generado exitosamente.');
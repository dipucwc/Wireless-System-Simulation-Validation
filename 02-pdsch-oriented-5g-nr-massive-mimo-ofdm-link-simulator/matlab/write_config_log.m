
%% 
function write_config_log(cfg, csvPath)
%% Configuration Log for Result Provenance:
%%
%{
The write_config_log function archives the exact run configuration next to the CSV result file, so that every
accepted result is a function of the locked configuration, the seed, the executed code, and the stored numerical
output. The log path is derived from the CSV name, and every configuration field is written as one line with numeric
fields rendered exactly and text fields verbatim, so that any stored result can be regenerated from its log and the
source code alone.

Input:

    cfg                           Complete simulation configuration structure.
    csvPath                       Path of the CSV result file the log accompanies.

Output:

    Log text file                 One line per configuration field, stored beside the CSV file.
%}
%% Log file path derived from the CSV name:
%%

[folder, base, ~] = fileparts(csvPath);            % Directory and base name of the CSV result file.
logPath = fullfile(folder, [base '_config.txt']);  % Log stored beside the CSV under a matching name.


%% One line per configuration field:
%%

fid = fopen(logPath, 'w');
fprintf(fid, 'Configuration log for %s\nGenerated: %s\n\n', [base '.csv'], datestr(now));
f = fieldnames(cfg);                               % All configuration fields in definition order.
for i = 1:numel(f)
    v = cfg.(f{i});
    if isnumeric(v) || islogical(v)
        fprintf(fid, '%-24s %s\n', f{i}, mat2str(v));   % Numeric fields rendered exactly.
    else
        fprintf(fid, '%-24s %s\n', f{i}, char(v));      % Text fields written verbatim.
    end
end
fclose(fid);
fprintf('Saved config log:  %s\n', logPath);
end

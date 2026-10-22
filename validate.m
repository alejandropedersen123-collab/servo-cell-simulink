function report = validate
%VALIDATE Run controller unit tests and full Simulink acceptance scenarios.
root=fileparts(mfilename('fullpath'));addpath(root);
results=runtests(fullfile(root,'tests'));
assert(numel(results)>=7,'No complete test suite discovered.');assertSuccess(results);
out=fullfile(root,'results');if ~isfolder(out),mkdir(out);end
writetable(table(string({results.Name})',[results.Passed]',[results.Failed]',[results.Duration]', ...
    'VariableNames',{'Test','Passed','Failed','DurationSeconds'}),fullfile(out,'unit-tests.csv'));
report=run_acceptance;
end

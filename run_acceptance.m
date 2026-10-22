function report = run_acceptance
%RUN_ACCEPTANCE Executable requirements against the generated Simulink model.
root=fileparts(mfilename('fullpath')); addpath(root); build_model;
outdir=fullfile(root,'results');if ~isfolder(outdir),mkdir(outdir);end
names=["nominal","payload_disturbance","emergency_stop","encoder_fault", ...
    "missing_part","process_timeout","stale_ack","held_start","travel_limit","weak_actuator","manual_jog"];
report=struct('scenario',{},'passed',{},'cycles',{},'maxPosition',{},'maxForce',{},'finalAlarm',{},'cycleTime',{},'stopDistance',{});
for k=1:numel(names)
    T=simulate_scenario(char(names(k))); S=cellctl.scenario(char(names(k)));
    assert(all(isfinite(T{:,:}),'all'),'Nonfinite simulation output.');
    assert(max(abs(T.force))<=S.maxForce+1e-6,'Motor force limit violated.');
    stopped=T.state==5 | T.state==0 | T.state==4;
    assert(all(abs(T.force(stopped))<1e-9),'Disabled or faulted state commands motor force.');
    cycleTime=NaN; stopDistance=NaN;
    if any(T.cycles>=1), cycleTime=T.time(find(T.cycles>=1,1))-.5; end
    switch names(k)
        case {"nominal","payload_disturbance","held_start"}
            assert(max(T.cycles)==1,'Expected exactly one completed cycle.');
            assert(max(T.alarm)==0,'Unexpected alarm in operating scenario.');
            assert(abs(T.position(end))<.006,'Did not return home.');
            assert(max(T.position)<.67,'Overshoot exceeds 20 mm.');
        case "emergency_stop"
            idx=T.time>=1.41 & T.time<3.2;
            assert(all(T.state(idx)==5),'Emergency did not latch.');
            assert(all(T.force(T.time>=1.41)==0),'Motor not inhibited after emergency.');
            assert(T.alarm(end)==0 && T.state(end)==0,'Disabled reset did not clear fault.');
            x0=T.position(find(T.time>=1.4,1));stopDistance=max(T.position(T.time>=1.4))-x0;
            assert(stopDistance<.06,'Modeled stop distance exceeds 60 mm.');
        case "encoder_fault"
            assert(all(T.state(T.time>=1.41)==5));assert(T.alarm(end)==2);
        case "missing_part"
            assert(all(T.state==0));assert(max(abs(T.position))<1e-10);
        case {"process_timeout","stale_ack"}
            assert(T.alarm(end)==5);assert(max(T.cycles)==0);
        case "travel_limit"
            assert(all(T.state==5));assert(T.alarm(end)==3);
        case "weak_actuator"
            assert(T.alarm(end)==4);assert(max(T.cycles)==0);
        case "manual_jog"
            assert(any(T.state==6));assert(max(abs(T.velocity))<.18);assert(max(T.cycles)==0);
    end
    report(k)=struct('scenario',char(names(k)),'passed',true,'cycles',max(T.cycles), ...
        'maxPosition',max(T.position),'maxForce',max(abs(T.force)), ...
        'finalAlarm',T.alarm(end),'cycleTime',cycleTime,'stopDistance',stopDistance);
    writetable(T(1:5:end,:),fullfile(outdir,[char(names(k)) '.csv']));
    if names(k)=="nominal", nominal=T; end
    if names(k)=="emergency_stop", emergency=T; end
    fprintf('PASS %s\n',names(k));
end
writetable(struct2table(report),fullfile(outdir,'acceptance.csv'));
fid=fopen(fullfile(outdir,'summary.json'),'w');cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s',jsonencode(struct('matlabVersion',version,'results',report),'PrettyPrint',true));clear cleanup;
fig=figure('Visible','off','Color','w','Position',[50 50 1200 760]);tiledlayout(2,2,'TileSpacing','compact');
nexttile;plot(nominal.time,[nominal.position nominal.target],'LineWidth',1.4);grid on;
xlabel('Time (s)');ylabel('Position (m)');legend('Axis','Target');title('Automatic transfer and return');
nexttile;plot(nominal.time,[nominal.velocity nominal.velocityReference],'LineWidth',1.4);grid on;
xlabel('Time (s)');ylabel('Velocity (m/s)');legend('Measured','Limited reference');title('Cascaded servo response');
nexttile;stairs(nominal.time,nominal.state,'LineWidth',1.5);grid on;ylim([-.3 6.3]);
yticks(0:6);yticklabels({'IDLE','INDEX','PROCESS','RETURN','COMPLETE','FAULT','MANUAL'});xlabel('Time (s)');title('PLC-style sequence');
nexttile;yyaxis left;plot(emergency.time,emergency.velocity,'LineWidth',1.5);ylabel('Velocity (m/s)');
yyaxis right;stairs(emergency.time,emergency.state,'LineWidth',1.2);ylabel('State');xlim([1 4]);grid on;
xlabel('Time (s)');title('Emergency: inhibit, brake, latch, reset');
sgtitle('SERVO TRANSFER CELL | Virtual commissioning');exportgraphics(fig,fullfile(outdir,'commissioning.png'),'Resolution',160);close(fig);
try
    print('-sservo_transfer_cell','-dpng','-r120',fullfile(outdir,'model.png'));
catch err
    warning('cellctl:Preview','Model preview unavailable: %s',err.message);
end
disp(struct2table(report));
end

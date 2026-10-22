function trace = simulate_scenario(name)
%SIMULATE_SCENARIO Run actual Simulink solver with isolated parameters.
root=fileparts(mfilename('fullpath')); addpath(root); model='servo_transfer_cell';
file=fullfile(root,'models',[model '.slx']);
if ~isfile(file), build_model; end
if ~bdIsLoaded(model), load_system(file); end
p=cellctl.parameters; S=cellctl.scenario(name); p.mass=S.mass; p.maxForce=S.maxForce;
in=Simulink.SimulationInput(model);
in=in.setVariable('commandData',S.commands,'Workspace',model);
in=in.setVariable('params',cellctl.parameter_vector(p),'Workspace',model);
in=in.setVariable('plantMass',p.mass,'Workspace',model);
in=in.setBlockParameter([model '/Position'],'InitialCondition',num2str(S.initialPosition));
in=in.setModelParameter('StopTime',num2str(S.stopTime));
out=sim(in);
t=out.position.Time;
names={'position','velocity','force','velocityReference','state','target','alarm','cycles','brake'};
trace=table(t,'VariableNames',{'time'});
for k=1:numel(names)
    ts=out.get(names{k});
    trace.(names{k})=interp1(ts.Time,squeeze(ts.Data),t,'previous','extrap');
end
end

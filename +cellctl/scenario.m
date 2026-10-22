function S = scenario(name)
%SCENARIO Inputs are zero-order-held. t0 and all transitions align with scans.
p=cellctl.parameters; t=(0:p.Ts:16)';
C=zeros(numel(t),10); C(:,1)=1; C(:,3)=1; C(:,7)=1;
C(t>=.5 & t<.7,2)=1; C(t>=5.5,4)=1;
S=struct('name',name,'commands',[t C],'stopTime',16,'mass',p.mass, ...
    'maxForce',p.maxForce,'initialPosition',0,'description','');
switch name
    case 'nominal'
        S.description='One pick-transfer-process-return cycle.';
    case 'payload_disturbance'
        C(t>=1.2 & t<3.2,8)=5; S.mass=12;
        C(:,4)=0; C(t>=7,4)=1; % Loaded axis settles later; acknowledge after arrival.
        S.description='50% payload increase plus 5 N external load pulse.';
    case 'emergency_stop'
        C(t>=1.4 & t<2.0,5)=1;
        C(t>=2.2 & t<2.4,6)=1; % Reset while enabled must be ignored.
        C(t>=3,1)=0; C(t>=3.2 & t<3.4,6)=1;
        S.description='Latched emergency, rejected live reset, reset while disabled.';
    case 'encoder_fault'
        C(t>=1.4,7)=0;
        S.description='Invalid encoder quality immediately inhibits motor command.';
    case 'missing_part'
        C(:,3)=0;
        S.description='Start rejected when part-present sensor is false.';
    case 'process_timeout'
        C(:,4)=0;
        S.description='Missing station acknowledgment produces a latched fault.';
    case 'stale_ack'
        C(:,4)=1;
        S.description='An acknowledgment already high before arrival cannot release return.';
    case 'held_start'
        C(t>=.5,2)=1;
        S.description='A held start button must never create repeated cycles.';
    case 'travel_limit'
        S.initialPosition=.75;
        S.description='Out-of-range position detected before motion.';
    case 'weak_actuator'
        S.maxForce=2;
        S.description='Severely limited force causes movement timeout, not a false completion.';
    case 'manual_jog'
        C(:,2)=0; C(t>=.5 & t<2.5,9)=1;
        C(t>=.6 & t<1.1,10)=.15; C(t>=1.4 & t<1.9,10)=-.15;
        S.description='Limited-velocity jog then release to idle.';
    otherwise
        error('cellctl:Scenario','Unknown scenario: %s',name);
end
S.commands=[t C];
end

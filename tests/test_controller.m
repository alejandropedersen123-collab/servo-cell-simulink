function tests=test_controller
tests=functiontests(localfunctions);
end
function testNoPartNoCycle(tc)
p=cellctl.parameter_vector(cellctl.parameters); c=[1 1 0 0 0 0 1 0 0 0];
[s,~,~,cy]=cellctl.sequence_step(0,0,c,p,zeros(1,8));
verifyEqual(tc,s,0); verifyEqual(tc,cy,0);
end
function testEmergencyWinsAndLatches(tc)
p=cellctl.parameter_vector(cellctl.parameters); c=[1 1 1 0 1 1 1 0 0 0];
[s,~,a,~,mem]=cellctl.sequence_step(0,0,c,p,zeros(1,8));
verifyEqual(tc,s,5); verifyEqual(tc,a,1);
c(5)=0;c(6)=0; [~,~,~,~,mem]=cellctl.sequence_step(0,0,c,p,mem);
c(6)=1; [s,~,a]=cellctl.sequence_step(0,0,c,p,mem);
verifyEqual(tc,s,5);verifyEqual(tc,a,1);
end
function testInvalidFeedbackCannotPropagate(tc)
p=cellctl.parameter_vector(cellctl.parameters);
[u,v,b,mem]=cellctl.servo_step(NaN,0,.65,1,0,p,[5 .2]);
verifyEqual(tc,[u v b mem],[0 0 1 0 0]);
end
function testForceAndAccelerationLimits(tc)
p=cellctl.parameter_vector(cellctl.parameters); mem=[0 0];
for k=1:500
    old=mem(2);[u,r,~,mem]=cellctl.servo_step(-1,0,.65,1,0,p,mem);
    verifyLessThanOrEqual(tc,abs(u),p(5)+1e-10);
    verifyLessThanOrEqual(tc,abs(r-old),p(7)*p(1)+1e-10);
end
verifyLessThan(tc,abs(mem(1)),100); % Sustained saturation cannot wind up forever.
end
function testMovementTimeout(tc)
p=cellctl.parameter_vector(cellctl.parameters); c=[1 1 1 0 0 0 1 0 0 0];mem=zeros(1,8);
for k=1:1000,[s,~,a,~,mem]=cellctl.sequence_step(0,0,c,p,mem);end
verifyEqual(tc,s,5);verifyEqual(tc,a,4);
end
function testCompletionRequiresLowVelocity(tc)
p=cellctl.parameter_vector(cellctl.parameters);c=[1 0 1 0 0 0 1 0 0 0];mem=[1 0 0 0 0 0 0 0];
for k=1:30,[s,~,~,~,mem]=cellctl.sequence_step(.65,.2,c,p,mem);end
verifyEqual(tc,s,1);
end
function testStaleAcknowledgmentRejected(tc)
p=cellctl.parameter_vector(cellctl.parameters);c=[1 0 1 1 0 0 1 0 0 0];
mem=[2 0 0 0 0 0 0 1];
[s,~,~,~,mem]=cellctl.sequence_step(.65,0,c,p,mem);verifyEqual(tc,s,2);
c(4)=0;[~,~,~,~,mem]=cellctl.sequence_step(.65,0,c,p,mem);
c(4)=1;[s,~,~,~,~]=cellctl.sequence_step(.65,0,c,p,mem);verifyEqual(tc,s,3);
end

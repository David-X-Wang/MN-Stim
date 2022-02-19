function y = notch_mult(X,f0);
%this script implements a multiple-frequency notch filter based on 
%quadratic programming. The width of the notches can be controlled by
%adjusting the amount of zero padding, Np. Nd is the length of the signal
%being filtered. In this example it is white noise. Note the depth of
%the notches are infinite, but it may not show in the plot because the exact
%notch frequencies may not be evaluated in the FFT. 
%author: Carlos E. Davila
%last modified: April 2021 by David Wang
[nrows Nd] = size(X);
Np = 0;
N = Nd + 2*Np;
Fs = 1000; %sampling frequency
T = 1/Fs; %sampling interval
 %notch frequencies in Hz (these are arbitrary)
%f0 = 299;
for k = 1:length(f0)
    w0 = 2*pi*f0(k)*T;
    A(2*(k-1)+1:2*k,:) = [cos([0:N-1]*w0)
        sin([0:N-1]*w0)];
end
P = eye(N) - A'*inv(A*A')*A;
x = [zeros(nrows,Np) X zeros(nrows,Np)]';
y1 = P*x;
y = y1(Np+1:Np+Nd,:)';
classdef cavity
    %CAVITY Summary of this class goes here
    %   Detailed explanation goes here

    properties
        name
        GDES
        PDES
    end
    properties (Constant)
        len = 1.038 %meters
    end
    methods
        function obj = cavity(cavity_name)
            obj.name = cavity_name;
            obj.GDES = lcaGetSmart(strcat(cavity_name,':ADES')); % Change to GDES
            obj.PDES = lcaGetSmart(strcat(cavity_name,':PDES'));
        end

        function [PHAS_scan , BMP_scan]=scan(obj,R)
            disp(['Scanning cavity ' obj.name])
            BMP_scan = zeros(1,length(R(3)+obj.PDES:R(5):R(4)+obj.PDES)); %Preallocation
            PHAS_scan = zeros(1,length(R(3)+obj.PDES:R(5):R(4)+obj.PDES)); %Preallocation
            count = 1;
            for p = R(3)+obj.PDES:R(5):R(4)+obj.PDES
                %lcaPut -- set sacan phase to p
                BMP_scan(count) = lcaGetSmart('BPMS:IN20:731:X');
                PHAS_scan(count) = lcaGetSmart(strcat(obj.name,':PHAS')) + p;
                count = count + 1;
            end
        end

        function fit(obj,x,y,R)
            x = x*pi/180;
            if isvector(y)
                % LLS
                B = transpose([ones(1,length(x)); sin(x); cos(x)]);
                a = inv(transpose(B)*B)*transpose(B)*transpose(y);
                plot(x,y,'ro')
                hold on
            else
                y_mean = mean(y);
                y_err = std(y)/(sqrt(N));
                errorbar(y_mean,y_err);
                errorbar(x,y_mean,y_err,'ro');
                hold on
                % LLS
                B = transpose([ones(1,length(x)); sin(x); cos(x)]);
                a = inv(transpose(B)*B)*transpose(B)*transpose(y_mean);
                %W-LLS
                W = zeros (length(x));
                for i = 1:length(x)
                    W(i,i) = 1/(y_err(i)^2);
                end
                a_w = inv(transpose(B)*W*B)*transpose(B)*W*transpose(y_mean);
                fit_w = a_w(1) + a_w(2)*sin(x) + a_w(3)*cos(x);
                plot(x,fit_w,'g');
                hold on
            end
            phi_f = atan2(a(2),a(3));

            fit = a(1) + a(2)*sin(x) + a(3)*cos(x);
            plot(x,fit,'b');
            xlabel('RF Phase (deg)')
            ylabel('BPM Pos. Reading (mm)')
            title({obj.name;get_time;['G=' num2str(R(1)) ' MV/m, \eta=XYZ mm, E=' num2str(R(2)*1000) ' MeV, \Phi=' num2str(phi_f)]})
            xL = get(gca,'XLim');
            line(xL,[0 0],'Color','r','LineStyle','--');
            yL = get(gca,'YLim');
            line([phi_f phi_f],yL,'Color','g','LineStyle','--');
            hold off
        end
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%uvoz in zapis podatkov(štirikrat je treba vstaviti ime datoteke mreže, v vrsticah 5, 10, 86, 88!)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lines = splitlines(fileread('lopatica_mreza_r1.txt')); %preberemo datoteko in jo zapišemo po vrsticah
iC = find(startsWith(strtrim(lines), 'celice'));   % vsaki vrstici odstranimo nepotrebne presledke, ker ko iščemo startswith nočemo presledkov pred 'celice'

%preberemo robne pogoje in jih damo v dve matriki in shranimo število točk
%in
fid = fopen('lopatica_mreza_r1.txt','r');

BC_temp = [];
BC_prestop = [];
BC_tok = [];

nT = 0;
nC = 0;

while ~feof(fid)

    vrstica = strtrim(fgetl(fid));

    % stevilo tock
    if startsWith(lower(vrstica),'tocke')

        nT = sscanf(vrstica,'tocke %d');

        % stevilo celic
    elseif startsWith(lower(vrstica),'celice')

        nC = sscanf(vrstica,'celice %d');

        % robni pogoji
    elseif startsWith(lower(vrstica),'pogoj')

        if contains(lower(vrstica),'temperatura')

            vrstica = strtrim(fgetl(fid));
            T = sscanf(vrstica,'temperatura: %f');

            vrstica = strtrim(fgetl(fid));
            N = str2double(vrstica);

            for i = 1:N
                id = str2double(strtrim(fgetl(fid)));
                BC_temp(end+1,:) = [id T];
            end

        elseif contains(lower(vrstica),'prestop')

            vrstica = strtrim(fgetl(fid));
            Tinf = sscanf(vrstica,'temperatura: %f');

            vrstica = strtrim(fgetl(fid));
           % h = sscanf(vrstica,'koeficient prestopa: %f');
            h = sscanf(vrstica,'%*[^0-9]%f');

            vrstica = strtrim(fgetl(fid));
            N = str2double(vrstica);

            for i = 1:N
                id = str2double(strtrim(fgetl(fid)));
                BC_prestop(end+1,:) = [id Tinf h];
            end

       
        elseif contains(lower(vrstica),'toplotni tok')

            vrstica = strtrim(fgetl(fid));
            topl_tok = sscanf(vrstica,'toplotni tok: %f');

            vrstica = strtrim(fgetl(fid));
            N = str2double(vrstica);

            for i = 1:N
               id = str2double(strtrim(fgetl(fid)));
               BC_tok(end+1,:) = [id topl_tok];
            end

        end
    end
end

fclose(fid);

tocke  = readmatrix('lopatica_mreza_r1.txt', 'Delimiter', {';', ','}, ...
    'Range', [2 1 1+nT 3]);
celice = readmatrix('lopatica_mreza_r1.txt', 'Delimiter', {';', ','}, ...
    'Range', [iC+1 1 iC+nC 5]);
celice = celice + 1; 

if isempty(BC_prestop)
    BC_prestop = zeros(size(tocke, 1), 3);
    prestop_prazen = true;
else
    BC_prestop(:,1) = BC_prestop(:,1) + 1;   % indeksi se začnejo z 0
    prestop_prazen = false;
end

% temperatura
if isempty(BC_temp)
    BC_temp = zeros(size(tocke, 1), 3);
    temp_prazen = true;
else
    BC_temp(:,1) = BC_temp(:,1) + 1;
    temp_prazen = false;
end

if isempty(BC_tok)
    BC_tok = zeros(size(tocke, 1), 3);
    tok_prazen = true;
else
    BC_tok(:,1) = BC_tok(:,1) + 1;
    tok_prazen = false;
end



%pridobljene podatke tocke razdelimo:
x = tocke(:,2); % x-koodrinate vozlisc
y = tocke(:,3); % y-koordinate vozlisc




% vsi indeksi točk iz celic
vse_tocke = celice(:,2:5);

% spremenljivke za shranjevanje
zunanji_rob = zeros(size(x, 1), 1);
rob = zeros(size(x, 1), 1);
notranji_rob = zeros(size(x, 1), 1);
notranja_tocka = zeros(size(x, 1), 1);

for i = 1:size(tocke,1)

    % kolikokrat se pojavi točka p
    st_pojavitev = sum(vse_tocke(:) == i);

    if st_pojavitev == 1
        zunanji_rob(i) = i;

    elseif st_pojavitev == 2
        rob(i) = i;

    elseif st_pojavitev == 3
        notranji_rob(i) = i;

    elseif st_pojavitev == 4
        notranja_tocka(i) = i;
    end

end

%zapišemo unikatne
%koordinate mreže ki jih uredijo po vrsti in vsakega zapišejo zgolj enkrat
xu = unique(x);
yu = unique(y);

Nx = length(xu);
Ny = length(yu);

ID = zeros(Ny,Nx);  %nastavimo matriko z vsemi možnimi kombinacijami koordinat, naredimo bounding box z matriko


for i = 1:size(tocke, 1)
    [~,ix] = ismember(x(i), xu); %pogledamo v katerem indeksu se nahaja x(i) v xu in isto za y
    [~,iy] = ismember(y(i), yu);

    ID(iy, ix) = i;  %točke predstavimo kot matriko

end


tocke = [tocke zeros(size(tocke,1),8)]; % matriki tocke dodamo osem stolpcev v katerih bomo za vsako točko napisali štiri mejne točke če jih ima 
ID_rob = zeros(size(ID,1)+2, size(ID,2)+2);
ID_rob(2:end-1, 2:end-1) = ID;  %matriko prestavimo

for i = 1:size(tocke, 1)

    [~,ix] = ismember(x(i), xu);
    [~,iy] = ismember(y(i), yu);

    ix = ix + 1; %ker smo matriki ID dodali prazno vrstico in stolpec na začetku
    iy = iy + 1;

    s = ID_rob(iy+1, ix);
    j = ID_rob(iy-1, ix);
    v = ID_rob(iy, ix+1);
    z = ID_rob(iy, ix-1);

    sv = ID_rob(iy+1, ix+1);
    sz = ID_rob(iy+1, ix-1);
    jv = ID_rob(iy-1, ix+1);
    jz = ID_rob(iy-1, ix-1);

    tocke(i, 4:11) = [s, j, v, z, sv, sz, jv, jz];
  
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%nastavimo matriki A in b, kjer A vsebuje koeficiente, b pa desni del enačb
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

A = zeros(nT, nT);
b = zeros(nT, 1);

delta_x = abs(xu(1)-xu(2));
k = 1;

for i = 1 : nT
    if ismember(i, BC_temp(:,1))
        [~,ix] = ismember(i, BC_temp(:,1));

        A(i, i) = 1;
        b(i, 1) = BC_temp(ix, 2);
    end

    if ismember(i, notranja_tocka)
        A(i, i) = -4;
        A(i, tocke(i, 4)) = 1;
        A(i, tocke(i, 5)) = 1;
        A(i, tocke(i, 6)) = 1;
        A(i, tocke(i, 7)) = 1;
    end

   
    if ismember(i, BC_prestop(:,1))
        [~,ix] = ismember(i, BC_prestop(:,1));
        Bi =  BC_prestop(ix, 3)*delta_x/k;
        b(i, 1) = -2*Bi*BC_prestop(ix, 2);

        if ismember(i, zunanji_rob)
            A(i, i) = -2*(Bi+1);
            for v = 4 : 7
                if tocke(i, v) == 0
                    continue
                end

                if ismember(tocke(i,v), ...
                        [zunanji_rob; notranji_rob; rob])

                    A(i,tocke(i,v)) = 1;

                end
            end
        end


        if ismember(i, rob)
            A(i, i) = -2*(Bi+2);
            for v = 4 : 7
                if tocke(i, v) == 0
                    continue
                end

                if ismember(tocke(i,v), ...
                        [zunanji_rob; notranji_rob; rob])

                    A(i,tocke(i,v)) = 1;

                end
                if ismember(tocke(i,v),notranja_tocka)

                    A(i,tocke(i,v)) = 2;

                end              
            end
        end

        if ismember(i, notranji_rob)
            A(i, i) = -2*(Bi+3);
            for v = 4 : 7
                if tocke(i, v) == 0
                    continue
                end

                if ismember(tocke(i,v), ...
                        [zunanji_rob; notranji_rob; rob])

                    A(i,tocke(i,v)) = 1;

                end
                if ismember(tocke(i,v),notranja_tocka)

                    A(i,tocke(i,v)) = 2;

                end              
            end
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    end     
    if ismember(i, BC_tok(:,1))
        [~,ix] = ismember(i, BC_tok(:,1));
        b(i, 1) = -2*delta_x*BC_tok(ix, 2)/k;

        if ismember(i, zunanji_rob)
            A(i, i) = -2;
            for v = 4 : 7
                if tocke(i, v) == 0
                    continue
                end

                if ismember(tocke(i,v), ...
                        [zunanji_rob; notranji_rob; rob])

                    A(i,tocke(i,v)) = 1;

                end
            end
        end


        if ismember(i, rob)
            A(i, i) = -4;
            for v = 4 : 7
                if tocke(i, v) == 0
                    continue
                end

                if ismember(tocke(i,v), ...
                        [zunanji_rob; notranji_rob; rob])

                    A(i,tocke(i,v)) = 1;

                end
                if ismember(tocke(i,v),notranja_tocka)

                    A(i,tocke(i,v)) = 2;

                end              
            end
        end

        if ismember(i, notranji_rob)
            A(i, i) = -6;
            for v = 4 : 7
                if tocke(i, v) == 0
                    continue
                end

                if ismember(tocke(i,v), ...
                        [zunanji_rob; notranji_rob; rob])

                    A(i,tocke(i,v)) = 1;

                end
                if ismember(tocke(i,v),notranja_tocka)

                    A(i,tocke(i,v)) = 2;

                end              
            end
        end           
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Izpis v binarni obliki
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[I, J, V] = find(A);          % vrstice, stolpci, vrednosti neničelnih elementov
nnzA = nnz(A);

fid = fopen('A.bin', 'wb');   % 'wb' = write binary
fwrite(fid, size(A,1), 'int32');   % število vrstic
fwrite(fid, size(A,2), 'int32');   % število stolpcev
fwrite(fid, nnzA,      'int32');   % število neničelnih
fwrite(fid, I - 1,     'int32');   % indeksi vrstic (0-based za C)
fwrite(fid, J - 1,     'int32');   % indeksi stolpcev (0-based za C)
fwrite(fid, V,         'double');  % vrednosti
fclose(fid);

fid = fopen('b.bin', 'wb');
fwrite(fid, numel(b), 'int32');    % dolžina
fwrite(fid, b,        'double');   % vrednosti
fclose(fid);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%še izpišemo skico mreže in robnih pogojev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure;

for i = 1:size(celice, 1)   %gre od 1 do števila vrstic v matriki cells
    cell_points = celice(i, :);  %vzame vse stolpce i-te vrstice in jih zapiše v vektor cell_points

    cell_points_1 = cell_points(2); %izpišemo si vse štiri točke ki omejujejo celico
    cell_points_2 = cell_points(3);
    cell_points_3 = cell_points(4);
    cell_points_4 = cell_points(5);

    x1 = x(cell_points_1);
    x2 = x(cell_points_2);
    x3 = x(cell_points_3);
    x4 = x(cell_points_4);

    y1 = y(cell_points_1);
    y2 = y(cell_points_2);
    y3 = y(cell_points_3);
    y4 = y(cell_points_4);

    plot([x1, x2, x3, x4, x1], [y1, y2, y3, y4, y1], 'b')
    hold on; %brez tega požene samo enkrat ker plot ustavi program
end

if any(BC_prestop(:))
  for i = 1:size(BC_prestop, 1)
    xi = tocke(BC_prestop(i, 1), 2);
    yi = tocke(BC_prestop(i, 1), 3);
    h = plot(xi, yi, 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.5 0]);
    if i == 1, h_prestop = h; end
  end
  legend(h_prestop,'Prestop', 'Location', 'best');
end


if any(BC_temp(:))
 for i = 1:size(BC_temp, 1)
    xi = tocke(BC_temp(i, 1), 2);
    yi = tocke(BC_temp(i, 1), 3);
    h = plot(xi, yi, 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'y');
    if i == 1, h_temp = h; end
 end
 legend(h_temp,'Temperaturni robni pogoj', 'Location', 'best');
end

if any(BC_tok(:))
    for i = 1:size(BC_tok, 1)
        xi = tocke(BC_tok(i, 1), 2);
        yi = tocke(BC_tok(i, 1), 3);
        h = plot(xi, yi, 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'y');
        if i == 1, h_temp = h; end
    end
    legend(h_temp,'toplotni tok', 'Location', 'best');
end


xlim([min(x)-0.01, max(x)+0.01]); %dodatki za lepši izris
ylim([min(y)-0.01, max(y)+0.01]);


all_pairs:=function(n)
  local divisors,result;
  divisors:=DivisorsInt(n);
  result:=Filtered(Tuples(divisors,2),t->t[1]*t[2]=n);
  return result;
end;


all_groups:=function(t1,t2)
  local g, list;
  list:=[];
  for g in AllSmallGroups(t2) do
    Add(list, [t1,g]);
  od;
  return list;
end;

all_E_G:=function(n)
  local t,list;
  list:=[];
  for t in all_pairs(n) do
    Append(list, all_groups(t[1],t[2]));
  od;
  return list;
end;

all_left_groups:=function(n)
  local t,p,semigroups,s,m, i,f;
  f := IO_File(Concatenation("data/left_groups", String(n), ".g"), "w");
  IO_WriteLine(f,"semigroups:=");
  semigroups:=[];
    for p in all_E_G(n) do
      # Print(p,"\n\n");
      m:=[];
      for i in [1..p[1]] do
        Add(m,One(p[2]));
      od;
      s:=MultiplicationTable(ReesMatrixSemigroup(p[2],[m]));
      Add(semigroups,s);
  od;
  IO_WriteLine(f,semigroups);
  IO_WriteLine(f, ";");
  IO_Flush(f);
  IO_Close(f);
  return semigroups;
end;

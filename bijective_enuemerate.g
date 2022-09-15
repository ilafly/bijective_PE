
read_left_groups:=function(n)
  local f;
  Read(Concatenation("left_groups/data/left_groups", String(n), ".g"));
  return EvalString("semigroups");
end;

is_automorphism := function(f,m)
  local n,x,y;
  n := Size(m);
  for x in [1..n] do
    for y in [1..n] do
      if not m[x][y]^f = m[x^f][y^f] then
        return false;
      fi;
    od;
  od;
  return true;
end;

automorphism_group := function(m)
  local n,l;
  n := Size(m);
  l := Filtered(SymmetricGroup(n), f->is_automorphism(f, m));
  return Group(l);
end;

s_xy := function(obj, x, y)
  return [obj!.semigroup[x][y], obj!.theta[x][y]];
end;

is_bijective := function(obj)
  local c, n, x, y;

  n := obj!.size;
  c := Cartesian([1..n],[1..n]);

  for x in c do
    if not Number(c, z->x=s_xy(obj, z[1], z[2])) = 1 then
      return false;
    fi;
  od;
  return true;
end;


twist_matrix := function(obj, f)
  local i,j,m,n;
  n := Size(obj);
  m := NullMat(n,n);
  for i in [1..n] do
    for j in [1..n] do
      if obj[i^Inverse(f)][j^Inverse(f)] <> 0 then
        m[i][j] := obj[i^Inverse(f)][j^Inverse(f)]^f;
      fi;
    od;
  od;
  return m;
end;

is_fixed := function(f, m)
  if twist_matrix(m, f) = m then
    return true;
  else
    return false;
  fi;
end;

fix := function(m)
  return Group(Filtered(automorphism_group(m), x->is_fixed(x, m)));
end;


create_file := function(n,k,m)
  local f,lines,perms,tmp1,tmp2;

  tmp1 := "";
  tmp2 := "";

  f := Filtered(fix(m), x->not x=());

  if f <> [] then

    perms := AsList(f);

    for k in perms do
      Append(tmp1, Concatenation(String(ListPerm(k,n)),",\n"));
      Append(tmp2, Concatenation(String(ListPerm(Inverse(k),n)),",\n"));
    od;

    lines := [
    "language ESSENCE' 1.0\n",
    Concatenation("letting S be ", String(m), "\n"),
    Concatenation("letting n be ", String(n), "\n"),
    "letting perms be [\n", tmp1, "]\n",
    "letting inverses be [\n", tmp2, "]\n",
    "find T : matrix indexed by [int(1..n), int(1..n)] of int(1..n)\n",
    "such that\n",
    "forAll x : int(1..n) .",
    "  allDiff(T[x,..]),\n",
    "forAll x,y,z : int(1..n) .",
    "  T[x,S[y,z]]=S[T[x,y],T[S[x,y],z]],\n",
    "forAll x,y,z : int(1..n) .",
    "  T[T[x,y],T[S[x,y],z]]=T[y,z],\n",
    ];

    Add(lines, Concatenation("forAll p : int(1..", String(Size(perms)), ") .\n\\
    flatten( [ T[i,j] | i : int(1..n), j : int(1..n)] )\n\\
    <=lex flatten( [ inverses[p,T[perms[p,i],perms[p,j]]] | i : int(1..n), j : int(1..n)] ),"));
  else
    lines := [
    "language ESSENCE' 1.0\n",
    Concatenation("letting S be ", String(m), "\n"),
    Concatenation("letting n be ", String(n), "\n"),
    "find T : matrix indexed by [int(1..n), int(1..n)] of int(1..n)\n",
    "such that\n",
    "forAll x,y,z : int(1..n) .",
    "  T[x,S[y,z]]=S[T[x,y],T[S[x,y],z]],\n",
    "forAll x,y,z : int(1..n) .",
    "  T[T[x,y],T[S[x,y],z]]=T[y,z],\n",
    ];
  fi;

  Add(lines, "\ntrue\n");
  return lines;
end;

# ok
# create_files := function(n)
#   local semigroups,f,x,s,k;
#   semigroups:=read_left_groups(n);
#
#   for k in [1..Size(semigroups)] do
#     s := create_file(n,k);
#     f := IO_File(Concatenation("pentagon", String(n), "_", String(k), ".eprime"), "w");
#     k := k+1;
#     for x in s do
#       IO_WriteLine(f, x);
#     od;
#     IO_Flush(f);
#     IO_Close(f);
#   od;
# end;


keep_pentagon := function(n, filename)
  local l, k, x, m, f, done;

  l := [];
  k := 0;

  f := IO_File(filename, "r");
  done := false;

  while not done do
    x := IO_ReadLine(f);
    if StartsWith(x, "Created information file") then
      done := true;
    elif StartsWith(x, "Solution") then
      m := EvalString(String(x{[46..Size(x)]}));
        k := k+1;
        Add(l, m);
      #fi;
    fi;
  od;
  Print("I found ", k, " solutions.\n");
  IO_Close(f);
  return l;
end;


run := function(filename, m, n, k)
  local s, l, f, x, t, output;

  t := [];
  l := 0;
  s := "../savilerow-1.9.1-mac/savilerow -run-solver -all-solutions -solutions-to-stdout-one-line ";

  Print("Running savilerow. ");
  output := Concatenation("output/output", String(n), "_", String(k));
  Exec(Concatenation(s, filename, " >", output));
  for x in keep_pentagon(n, output) do
    Add(t, x);
    l := l+1;
  od;

  f := IO_File(Concatenation("data/pentagon", String(n),"_", String(k), ".g"), "w");

  IO_WriteLine(f, Concatenation("semigroup", " := ", String(m), ";"));
  IO_WriteLine(f, Concatenation("sols", " := ["));
  for x in t do
    IO_WriteLine(f, Concatenation(String(x),","));
  od;
  IO_WriteLine(f, "];\n\n");
  IO_Flush(f);
  IO_Close(f);

  return l;
end;

construct := function(n)
  local semigroups, filename, t0, t1, mytime, k, s, f, x, l;

  semigroups:=read_left_groups(n);
  t0 := NanosecondsSinceEpoch();

  l := 0;

  LogTo();
  LogTo(Concatenation("log/pentagon", String(n), ".log"));

  for k in [1..Size(semigroups)] do
    s := create_file(n,k,semigroups[k]);
    f := IO_File(Concatenation("eprime/pentagon", String(n), "_", String(k), ".eprime"), "w");
    for x in s do
    IO_WriteLine(f, x);
    od;
    IO_Flush(f);
    IO_Close(f);

    filename := Concatenation("eprime/pentagon", String(n), "_", String(k), ".eprime");
    l := l+run(filename, semigroups[k],  n, k);
  od;

  t1 := NanosecondsSinceEpoch();
  mytime := Int(Float((t1-t0)/10^6));
  Print("I constructed ", l, " solutions in ", mytime, "ms (=", StringTime(mytime), ")\n");

end;

bijectives_solutions := function(n)
  local solutions, k, semigroups,semigroup,bijectives,list,s,t,thetas,x,filename,f;
  semigroups:=read_left_groups(n);
  bijectives:=[];
  t:=0;
  for k in [1..Size(semigroups)] do
    Read(Concatenation("data/pentagon", String(n), "_", String(k), ".g"));
    semigroup:=EvalString("semigroup");
    thetas:=EvalString("sols");
    t := t+Size(thetas);

    list:=[];
    for x in thetas do
      Add(list, rec( semigroup := semigroup, theta := x, size := Size(semigroup)));
    od;

    filename:=Concatenation("data/bijectives/bijectives", String(n),"_", String(k), ".g");
    f := IO_File(filename, "w");
    IO_WriteLine(f, "semigroup:=");
    IO_WriteLine(f, Concatenation(String(semigroups[k]),";"));
    IO_WriteLine(f, "solutions:=[");
    for s in list do
      if is_bijective(s) then
        Add(bijectives,s);
        IO_WriteLine(f, Concatenation(String(s!.theta), ","));
      fi;
    od;
    IO_WriteLine(f, "];\n");
    IO_Flush(f);
    IO_Close(f);
  od;
  
  filename:=Concatenation("data/bijectives/bijectives", String(n), ".g");
  f := IO_File(filename, "w");
  for s in bijectives do
    IO_WriteLine(f, s);
  od;
  IO_Flush(f);
  IO_Close(f);

  return Size(bijectives);
end;

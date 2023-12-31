(* Integrantes *)
(* Bruno Oliveira Guilhem - 00308691 *)
(* Davi Haas Rodrigues - 00288844 *)
(* Laura Cárdenas Grippa - 00219351 *)

(* auxiliares *)

let rec lookup amb x  =
  match amb with
    [] -> None
  | (y, item) :: tl -> if (y=x) then Some item else lookup tl x

let rec update amb x item  =
  (x,item) :: amb


(* remove elementos repetidos de uma lista *)
let nub l =
  let ucons h t = if List.mem h t then t else h::t in
  List.fold_right ucons l []


(* calcula  l1 - l2 (como sets) *)
let diff (l1:'a list) (l2:'a list) : 'a list =
  List.filter (fun a -> not (List.mem a l2)) l1


(* tipos de L1 *)

(* ALTERADO *)
type tipo =
    TyInt
  | TyBool
  | TyFn     of tipo * tipo
  | TyPair   of tipo * tipo
  | TyEither of tipo * tipo
  | TyList   of tipo
  | TyMaybe  of tipo
  | TyVar    of int   (* variáveis de tipo -- números *)

type politipo = (int list) * tipo


(* free type variables em um tipo *)

(* ALTERADO *)
let rec ftv (tp:tipo) : int list =
  match tp with
    TyInt
  | TyBool            -> []
  | TyFn(t1,t2)
  | TyPair(t1,t2)
  | TyEither(t1, t2)  ->  (ftv t1) @ (ftv t2)
  | TyList(t)
  | TyMaybe(t)        -> (ftv t)
  | TyVar n           -> [n]


(* impressao legível de monotipos  *)

(* ALTERADO *)
let rec tipo_str (tp:tipo) : string =
  match tp with
    TyInt             -> "int"
  | TyBool            -> "bool"
  | TyFn   (t1,t2)    -> "("  ^ (tipo_str t1) ^ "->" ^ (tipo_str t2) ^ ")"
  | TyPair (t1,t2)    -> "("  ^ (tipo_str t1) ^  "*" ^ (tipo_str t2) ^ ")"
  | TyEither (t1, t2) -> "(either " ^ (tipo_str t1) ^ " " ^ (tipo_str t2) ^ ")"
  | TyList (t)        -> (tipo_str t) ^ " list"
  | TyMaybe (t)       -> "maybe " ^ (tipo_str t)
  | TyVar  n          -> "X" ^ (string_of_int n)


(* expressões de L1 sem anotações de tipo   *)

type ident = string

type bop = Sum | Sub | Mult | Eq | Gt | Lt | Geq | Leq
(* ALTERAR *)
type expr  =
    Num       of int
  | Bool      of bool
  | Var       of ident
  | Binop     of bop * expr * expr
  | Pair      of expr * expr
  | Fst       of expr
  | Snd       of expr
  | If        of expr * expr * expr
  | Fn        of ident * expr
  | App       of expr * expr
  | Let       of ident * expr * expr
  | LetRec    of ident * ident * expr * expr
  | Pipe      of expr * expr
  | Nil
  | Cons      of expr * expr
  | PMatchList of expr * expr * ident * ident * expr
  | Nothing
  | Just      of expr
  | PMatchMaybe of expr * expr * ident * expr
  | Left      of expr
  | Right     of expr
  | PMatchEither of expr * ident * expr * ident * expr



(* impressão legível de expressão *)

(* ALTERAR *)
let rec expr_str (e:expr) : string  =
  match e with
    Num n   -> string_of_int  n
  | Bool b  -> string_of_bool b
  | Var x -> x
  | Binop (o,e1,e2) ->
      let s = (match o with
            Sum  -> "+"
          | Sub  -> "-"
          | Mult -> "*"
          | Leq  -> "<="
          | Geq  -> ">="
          | Eq   -> "="
          | Lt   -> "<"
          | Gt   -> ">") in
      "( " ^ (expr_str e1) ^ " " ^ s ^ " " ^ (expr_str e2) ^ " )"
  | Pair (e1,e2) ->  "(" ^ (expr_str e1) ^ "," ^ (expr_str e2) ^ ")"
  | Fst e1 -> "fst " ^ (expr_str e1)
  | Snd e1 -> "snd " ^ (expr_str e1)
  | If (e1,e2,e3) -> "(if " ^ (expr_str e1) ^ " then "
                     ^ (expr_str e2) ^ " else "
                     ^ (expr_str e3) ^ " )"
  | Fn (x,e1) -> "(fn " ^ x ^ " => " ^ (expr_str e1) ^ " )"
  | App (e1,e2) -> "(" ^ (expr_str e1) ^ " " ^ (expr_str e2) ^ ")"
  | Let (x,e1,e2) -> "(let " ^ x ^ "=" ^ (expr_str e1) ^ "\nin "
                     ^ (expr_str e2) ^ " )"
  | LetRec (f,x,e1,e2) -> "(let rec " ^ f ^ "= fn " ^ x ^ " => "
                          ^ (expr_str e1) ^ "\nin " ^ (expr_str e2) ^ " )"
  | Pipe (e1,e2) -> "( " ^ (expr_str e1) ^ "|>" ^ (expr_str e2) ^ " )"
  | Nil -> "Nil"
  | Cons (e1,e2) -> (expr_str e1) ^ "::" ^ (expr_str e2)
  | PMatchList (e1,e2,x,xs,e3) -> "match " ^ (expr_str e1) ^
                                " with Nil => " ^ (expr_str e2) ^
                                " | " ^ x ^ "::" ^ xs ^ " =>" ^ (expr_str e3)
  | Nothing -> "Nothing"
  | Just(e1) -> "Just( " ^ (expr_str e1) ^ " )"
  | PMatchMaybe (e1,e2,x,e3) -> "match " ^ (expr_str e1) ^
                              " with Nothing => " ^ (expr_str e2) ^
                              " | Just " ^ x ^ " => " ^ (expr_str e3)
  | Left(e1) -> "left " ^ (expr_str e1)
  | Right(e1) -> "right " ^ (expr_str e1)
  | PMatchEither (e1,x,e2,y,e3) -> "match " ^ (expr_str e1) ^
                                  " with left " ^ x ^ " => " ^ (expr_str e2) ^
                                  " | right " ^ y ^ " => " ^ (expr_str e3)

(* ambientes de tipo - modificados para polimorfismo *)

type tyenv = (ident * politipo) list


(* calcula todas as variáveis de tipo livres
   do ambiente de tipos *)
(* ALTERADO *)
let rec ftv_amb' (g:tyenv) : int list =
  match g with
    []           -> []
  | (_,(vars,tp))::t  -> (diff (ftv tp) vars)  @  (ftv_amb' t)


let ftv_amb (g:tyenv) : int list = nub (ftv_amb' g)


(* equações de tipo  *)

type equacoes_tipo = (tipo * tipo) list

(*
   a lista
       [ (t1,t2) ; (u1,u2) ]
   representa o conjunto de equações de tipo
       { t1=t2, u1=u2 }
 *)


(* imprime equações *)

let rec print_equacoes (c:equacoes_tipo) =
  match c with
    []       ->
      print_string "\n";
  | (a,b)::t ->
      print_string (tipo_str a);
      print_string " = ";
      print_string (tipo_str b);
      print_string "\n";
      print_equacoes t



(* código para geração de novas variáveis de tipo *)

let lastvar = ref 0

(* ALTERADO *)
let newvar (_:unit) : int =
  let x = !lastvar
  in lastvar := (x+1) ; x

(* substituições de tipo *)

type subst = (int * tipo) list


(* imprime substituições  *)

let rec print_subst (s:subst) =
  match s with
    []       ->
      print_string "\n";
  | (a,b)::t ->
      print_string ("X" ^ (string_of_int a));
      print_string " |-> ";
      print_string (tipo_str b);
      print_string "\n";
      print_subst t


(* aplicação de substituição a tipo *)
(* ALTERADO *)
let rec appsubs (s:subst) (tp:tipo) : tipo =
  match tp with
    TyInt             -> TyInt
  | TyBool            -> TyBool
  | TyFn     (t1,t2)  -> TyFn     (appsubs s t1, appsubs s t2)
  | TyPair   (t1,t2)  -> TyPair   (appsubs s t1, appsubs s t2)
  | TyEither (t1,t2)  -> TyEither (appsubs s t1, appsubs s t2)
  | TyList   (t1)     -> TyList   (appsubs s t1)
  | TyMaybe  (t1)     -> TyMaybe  (appsubs s t1)
  | TyVar  x        -> (match lookup s x with
        None        -> TyVar x
      | Some tp'    -> tp')



(* aplicação de substituição a coleção de constraints *)
let rec appconstr (s:subst) (c:equacoes_tipo) : equacoes_tipo =
  List.map (fun (a,b) -> (appsubs s a,appsubs s b)) c


(* ALTERADO *)
(* composição de substituições: s1 o s2  *)
let rec compose (s1:subst) (s2:subst) : subst =
  let r1 = List.map (fun (x,y) -> (x, appsubs s1 y))      s2 in
  let (vs,_) = List.split s2                                 in
  let r2 = List.filter (fun (x,_) -> not (List.mem x vs)) s1 in
  r1@r2


(* testa se variável de tipo ocorre em tipo *)
(* ALTERADO *)
let rec var_in_tipo (v:int) (tp:tipo) : bool =
  match tp with
    TyInt             -> false
  | TyBool            -> false
  | TyFn     (t1,t2)  -> (var_in_tipo v t1) || (var_in_tipo v t2)
  | TyPair   (t1,t2)  -> (var_in_tipo v t1) || (var_in_tipo v t2)
  | TyEither (t1,t2)  -> (var_in_tipo v t1) || (var_in_tipo v t2)
  | TyList   (t1)     -> (var_in_tipo v t1)
  | TyMaybe  (t1)     -> (var_in_tipo v t1)
  | TyVar  x          -> v=x


(* cria novas variáveis para politipos quando estes são instanciados *)

let rec renamevars (pltp : politipo) : tipo =
  match pltp with
    ( []       ,tp)  -> tp
  | ((h::vars'),tp)  -> let h' = newvar() in
      appsubs [(h,TyVar h')] (renamevars (vars',tp))


(* unificação *)

exception UnifyFail of (tipo*tipo)

(* ALTERADO *)
let rec unify (c:equacoes_tipo) : subst =
  match c with
    []                                     -> []
  | (TyInt,TyInt)  ::c'                    -> unify c'
  | (TyBool,TyBool)::c'                    -> unify c'
  | (TyFn(x1,y1),TyFn(x2,y2))::c'          -> unify ((x1,x2)::(y1,y2)::c')
  | (TyPair(x1,y1),TyPair(x2,y2))::c'      -> unify ((x1,x2)::(y1,y2)::c')
  | (TyEither(x1,y1),TyEither(x2,y2))::c'  -> unify ((x1,x2)::(y1,y2)::c')
  | (TyList(x1),TyList(x2))::c'            -> unify ((x1,x2)::c')
  | (TyMaybe(x1),TyMaybe(x2))::c'          -> unify ((x1,x2)::c')
  | (TyVar x1, TyVar x2)::c' when x1=x2    -> unify c'

  | (TyVar x1, tp2)::c'                  -> if var_in_tipo x1 tp2
      then raise (UnifyFail(TyVar x1, tp2))
      else compose
          (unify (appconstr [(x1,tp2)] c'))
          [(x1,tp2)]

  | (tp1,TyVar x2)::c'                  -> if var_in_tipo x2 tp1
      then raise (UnifyFail(tp1,TyVar x2))
      else compose
          (unify (appconstr [(x2,tp1)] c'))
          [(x2,tp1)]

  | (tp1,tp2)::_' -> raise (UnifyFail(tp1,tp2))



exception CollectFail of string


let rec collect (g:tyenv) (e:expr) : (equacoes_tipo * tipo)  =

  match e with
    Var x   ->
      (match lookup g x with
         None        -> raise (CollectFail x)
       | Some pltp -> ([],renamevars pltp))  (* instancia poli *)

  | Num _ -> ([],TyInt)

  | Bool _  -> ([],TyBool)

  | Binop (o,e1,e2) ->
      if List.mem o [Sum;Sub;Mult]
      then
        let (c1,tp1) = collect g e1 in
        let (c2,tp2) = collect g e2 in
        (c1@c2@[(tp1,TyInt);(tp2,TyInt)] , TyInt)
      else
        let (c1,tp1) = collect g e1 in
        let (c2,tp2) = collect g e2 in
        (c1@c2@[(tp1,TyInt);(tp2,TyInt)] , TyBool)

  | Pair (e1,e2) ->
      let (c1,tp1) = collect g e1 in
      let (c2,tp2) = collect g e2 in
      (c1@c2, TyPair(tp1,tp2))

  | Fst e1 ->
      let tA = newvar() in
      let tB = newvar() in
      let (c1,tp1) = collect g e1 in
      (c1@[(tp1,TyPair(TyVar tA, TyVar tB))], TyVar tA)

  | Snd e1 ->
      let tA = newvar() in
      let tB = newvar() in
      let (c1,tp1) = collect g e1 in
      (c1@[(tp1,TyPair(TyVar tA,TyVar tB))], TyVar tB)

  | If (e1,e2,e3) ->
      let (c1,tp1) = collect g e1 in
      let (c2,tp2) = collect g e2 in
      let (c3,tp3) = collect g e3 in
      (c1@c2@c3@[(tp1,TyBool);(tp2,tp3)], tp2)

  | Fn (x,e1) ->
      let tA       = newvar()           in
      let g'       = (x,([],TyVar tA)):: g in
      let (c1,tp1) = collect g' e1      in
      (c1, TyFn(TyVar tA,tp1))

  | App (e1,e2) ->
      let (c1,tp1) = collect  g e1 in
      let (c2,tp2) = collect  g e2  in
      let tA       = newvar()       in
      (c1@c2@[(tp1,TyFn(tp2,TyVar tA))]
      , TyVar tA)


  | Let (x,e1,e2) ->
      let (c1,tp1) = collect  g e1                    in

      let s1       = unify c1                         in
      let tf1      = appsubs s1 tp1                   in
      let polivars = nub (diff (ftv tf1) (ftv_amb g)) in
      let g'       = (x,(polivars,tf1))::g            in

      let (c2,tp2) = collect  g' e2                   in
      (c1@c2, tp2)

  | LetRec (f,x,e1,e2) ->
      let tA = newvar() in
      let tB = newvar() in
      let g2 = (f,([],TyFn(TyVar tA,TyVar tB)))::g            in
      let g1 = (x,([],TyVar tA))::g2                          in
      let (c1,tp1) = collect g1 e1                          in

      let s1       = unify (c1@[(tp1,TyVar tB)])            in
      let tf1      = appsubs s1 (TyFn(TyVar tA,TyVar tB))   in
      let polivars = nub (diff (ftv tf1) (ftv_amb g))       in
      let g'       = (f,(polivars,tf1))::g                    in

      let (c2,tp2) = collect g' e2                          in
      (c1@[(tp1,TyVar tB)]@c2, tp2)

  | Pipe (e1,e2) ->
      let (c1,tp1) = collect g e1 in
      let (c2,tp2) = collect g e2 in
      let tA = newvar() in
      (c1@c2@[(tp2,TyFn(tp1,TyVar tA))],TyVar tA)

  | Nil -> ([], TyList( TyVar(newvar())))

  | Cons (e1,e2) ->
       let (c1, tp1) =  collect g e1 in
       let (c2, tp2) = collect g e2 in
       (c1@c2@[(tp2, TyList tp1)],tp2)

  | PMatchList (e1,e2,x,xs,e3) ->
       let (c1, tp1) = collect g  e1 in
       let (c2, tp2) = collect g e2 in
       let xNew      = TyVar (newvar()) in
       let g'        = (x,([], xNew))::(xs, ([], tp1)):: g in
       let (c3, tp3) = collect g' e3 in
       (c1@c2@c3@[(tp1, TyList(xNew)); (tp2, tp3)], tp2)

  | Nothing -> ([], TyMaybe(TyVar(newvar())))

  | Just (e) ->
     let (c1, tp1) = collect g e in
     (c1,TyMaybe(tp1))

  | PMatchMaybe (e1, e2, x, e3) ->
       let (c1, tp1) = collect g  e1 in
       let (c2, tp2) = collect g e2 in
       let xNew = TyVar(newvar()) in
       let g' = (x, ([], xNew))::g in
       let (c3, tp3) = collect g' e3 in
       (c1@c2@c3@[(tp1, TyMaybe(xNew)); (tp2, tp3)], tp2)

  | Left (e1) ->
       let (c,tp) = collect g e1 in
       let xNew = TyVar(newvar()) in
       (c,TyEither(tp, xNew))

  | Right (e1) ->
       let (c,tp) = collect g e1 in
       let xNew = TyVar(newvar()) in
       (c,TyEither(xNew,tp))

  | PMatchEither (e1,x,e2,y,e3) ->
       let (c1,tp1) = collect g  e1 in
       let xNew = TyVar(newvar()) in
       let yNew = TyVar(newvar()) in
       let gx = (x, ([], xNew))::g in
       let (c2,tp2) = collect gx e2 in
       let gy = (y, ([], yNew))::g in
       let (c3,tp3) = collect gy e3 in
       (c1@c2@c3@[(tp1, TyEither(xNew, yNew)); (tp2, tp3)], tp2)


        (*===============================================*)
(* ALTERADO *)
type valor =
    VNum   of int
  | VBool  of bool
  | VPair  of valor * valor
  | VClos  of ident * expr * renv
  | VRclos of ident * ident * expr * renv
  | VNil
  | VList of valor * valor
  | VJust  of valor
  | VNothing
  | VLeft of valor
  | VRight of valor
and
  renv = (ident * valor) list

exception BugTypeInfer
exception DivZero


(* ALTERADO *)
let rec valor_str (v:valor) : string =
  match v with
    VNum n            -> string_of_int n
  | VBool _           -> "bool"
  | VPair(v1,v2)     -> "(" ^ valor_str v1 ^ "," ^ valor_str v2 ^ ")"
  | VClos _           -> "fn"
  | VRclos _          -> "fn"
  | VNil              -> "Nil"
  | VList(v1,v2)     -> "(" ^ valor_str v1 ^ "," ^ valor_str v2 ^ ")"
  | VJust(v1)         -> "(" ^ valor_str v1 ^ ")"
  | VNothing          -> "nothing"
  | VLeft(v1)         -> "(" ^ valor_str v1 ^ ")"
  | VRight(v1)        -> "(" ^ valor_str v1 ^ ")"


let compute (oper: bop) (v1: valor) (v2: valor) : valor =
  match (oper, v1, v2) with
    (Sum, VNum(n1), VNum(n2)) -> VNum (n1 + n2)
  | (Sub, VNum(n1), VNum(n2)) -> VNum (n1 - n2)
  | (Mult, VNum(n1),VNum(n2)) -> VNum (n1 * n2)
  | (Eq, VNum(n1), VNum(n2))  -> VBool (n1 = n2)
  | (Gt, VNum(n1), VNum(n2))  -> VBool (n1 > n2)
  | (Lt, VNum(n1), VNum(n2))  -> VBool (n1 < n2)
  | (Geq, VNum(n1), VNum(n2)) -> VBool (n1 >= n2)
  | (Leq, VNum(n1), VNum(n2)) -> VBool (n1 <= n2)
  | _ -> raise BugTypeInfer

(* ALTERADO *)
let rec eval (renv:renv) (e:expr) : valor =
  match e with
    Num n -> VNum n

  | Bool b -> VBool b

  | Var x ->
      (match lookup renv x with
         None -> raise BugTypeInfer
       | Some v -> v)

  | Binop(oper,e1,e2) ->
      let v1 = eval renv e1 in
      let v2 = eval renv e2 in
      compute oper v1 v2

  | Pair(e1,e2) ->
      let v1 = eval renv e1 in
      let v2 = eval renv e2
      in VPair(v1,v2)

  | Fst e ->
      (match eval renv e with
       | VPair(v1,_) -> v1
       | _ -> raise BugTypeInfer)

  | Snd e ->
      (match eval renv e with
       | VPair(_,v2) -> v2
       | _ -> raise BugTypeInfer)


  | If(e1,e2,e3) ->
      (match eval renv e1 with
         VBool true  -> eval renv e2
       | VBool false -> eval renv e3
       | _ -> raise BugTypeInfer )

  | Fn (x,e1) ->  VClos(x,e1,renv)

  | App(e1,e2) ->
      let v1 = eval renv e1 in
      let v2 = eval renv e2 in
      (match v1 with
         VClos(x,ebdy,renv') ->
           let renv'' = update renv' x v2
           in eval renv'' ebdy

       | VRclos(f,x,ebdy,renv') ->
           let renv''  = update renv' x v2 in
           let renv''' = update renv'' f v1
           in eval renv''' ebdy
       | _ -> raise BugTypeInfer)

  | Let(x,e1,e2) ->
      let v1 = eval renv e1
      in eval (update renv x v1) e2

  | LetRec(f,x,e1,e2)  ->
      let renv'= update renv f (VRclos(f,x,e1,renv))
      in eval renv' e2

  | Pipe(e1,e2) ->
    let v1 = eval renv e1 in
    let close = eval renv e2 in
      (match close with
          VClos(x,ebdy,renv') ->
            let renv'' = update renv' x v1
            in eval renv'' ebdy

        | VRclos(f,x,ebdy,renv') ->
            let renv''  = update renv' x v1 in
            let renv''' = update renv'' f close
            in eval renv''' ebdy
        | _ -> raise BugTypeInfer)

  | Nil -> VNil

  | Cons(e1,e2) ->
      let v1 = eval renv e1 in
      let v2 = eval renv e2 in
      VList(v1,v2)

  | PMatchList (e1,e2,x,xs,e3) ->
    let v1 = eval renv e1 in
    (match v1 with
    | VNil -> eval renv e2
    | VList(v,vs) -> eval (update (update renv x v) xs vs) e3
    | _ -> raise BugTypeInfer )

  | Nothing -> VNothing

  | Just(e1) ->
      let v1 = eval renv e1 in
      VJust(v1)

  | PMatchMaybe(e1,e2,x,e3) ->
      let v1 = eval renv e1 in
      (match v1 with
      | VNothing -> eval renv e2
      | VJust (v) -> eval (update renv x v) e3
      | _ -> raise BugTypeInfer )

  | Left(e1) -> VLeft(eval renv e1)

  | Right(e1) -> VRight (eval renv e1)

  | PMatchEither (e1,x,e2,y,e3) ->
      let v1 = eval renv e1 in
      (match v1 with
      | VLeft (v) -> eval (update renv x v) e2
      | VRight (v) -> eval (update renv y v) e3
      | _ -> raise BugTypeInfer )

(* INFERÊNCIA DE TIPOS - CHAMADA PRINCIPAL *)

let type_infer (e:expr) : unit =
  print_string "\nExpressao:\n";
  print_string (expr_str e);
  (* print_string ""; *)
  try
    let (c,tp) = collect [] e  in
    let s      = unify c       in
    let tf     = appsubs s tp  in
    let v = eval [] e          in
    print_string "\n\nResultado: ";
    print_string (valor_str v);
    print_string "\n\nEquacoes de tipo coletadas:\n";
    print_equacoes c;
    print_string "Tipo inferido: ";
    print_string (tipo_str tp);
    print_string "\n\nSubstituicao produzida por unify:\n";
    print_subst s;
    print_string "Tipo inferido (apos subs): ";
    print_string (tipo_str tf);
    print_string "\n\n"

  with

  | CollectFail x   ->
      print_string "Erro: variavel ";
      print_string x;
      print_string " nao declarada!\n\n"

  | UnifyFail (tp1,tp2) ->
      print_string "Erro: impossível unificar os tipos\n* ";
      print_string (tipo_str tp1);
      print_string "\n* ";
      print_string (tipo_str tp2);
      print_string "\n\n"

(* =============== ÁREA DE TESTES =============== *)

(* Teste 1 *)
let sum2 = Binop(Sum, Num(10), Num(12))

(* Teste 2 *)
(*
     let x:int = 2
     in let foo: int --> int = fn y:int => x + y
        in let x: int = 5
           in foo 10
*)

(* Teste Pair and Fst | Valor: 64*)
let tFst1 = Fst(Pair(Num(64), Bool(false)))

(* Teste Pair and Snd | Valor: false*)
let tSnd1 = Snd(Pair(Num(64), Bool(false)))

(* ----- *)

(* Teste If then Else True | Valor: 1*)
let tIF1 = If (Bool(true), Num(1), Num(2))

(* Teste If then Else False | Valor: 2*)
let tIF2 = If (Bool(false), Num(1), Num(2))

(* ----- *)

(* Teste Let, Fn, Binop | Valor: 12*)
let e'' = Let("x", Num 5, App(Var "foo", Num 10))
let e'  = Let("foo", Fn("y", Binop(Sum, Var "x", Var "y")), e'')
let tst = Let("x", Num(2), e')

(* ----- *)

(* Teste Cons *)
let lst = Cons(Num(3), Cons(Num(4), Cons(Num(5), Nil)))

(* ----- *)

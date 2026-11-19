.pragma library

const FUNCS = {
    sqrt: Math.sqrt, cbrt: Math.cbrt, abs: Math.abs,
    sin: Math.sin, cos: Math.cos, tan: Math.tan,
    asin: Math.asin, acos: Math.acos, atan: Math.atan,
    log: Math.log10, ln: Math.log, log2: Math.log2, exp: Math.exp,
    round: Math.round, floor: Math.floor, ceil: Math.ceil
};
const CONSTS = { pi: Math.PI, e: Math.E, tau: Math.PI * 2 };

function tokenize(src) {
    const s = src.replace(/×/g, "*").replace(/÷/g, "/").replace(/π/g, "pi").replace(/\*\*/g, "^")
        .replace(/([\d.)])\s*x\s*(?=[\d.(])/gi, "$1*");
    const tokens = [];
    let i = 0;
    while (i < s.length) {
        const c = s[i];
        if (/\s/.test(c)) { i++; continue; }
        const num = s.slice(i).match(/^(\d[\d,_]*(\.\d*)?|\.\d+)([eE][+-]?\d+)?/);
        if (num) {
            tokens.push({ t: "num", v: parseFloat(num[0].replace(/[,_]/g, "")) });
            i += num[0].length;
            continue;
        }
        const word = s.slice(i).match(/^[a-zA-Z][a-zA-Z0-9]*/);
        if (word) {
            tokens.push({ t: "id", v: word[0].toLowerCase() });
            i += word[0].length;
            continue;
        }
        if ("+-*/%^()!".includes(c)) {
            tokens.push({ t: "op", v: c });
            i++;
            continue;
        }
        return null;
    }
    return tokens;
}

function parse(tokens) {
    let pos = 0;
    const peek = () => tokens[pos];
    const isOp = v => peek() && peek().t === "op" && peek().v === v;

    function expr() {
        let left = term();
        while (isOp("+") || isOp("-")) {
            const op = tokens[pos++].v;
            const right = term();
            left = op === "+" ? left + right : left - right;
        }
        return left;
    }

    function term() {
        let left = unary();
        for (;;) {
            if (isOp("*") || isOp("/") || isOp("%")) {
                const op = tokens[pos++].v;
                const right = unary();
                left = op === "*" ? left * right : op === "/" ? left / right : left % right;
            } else if (peek() && (peek().t === "id" || isOp("("))) {
                left = left * unary();
            } else {
                return left;
            }
        }
    }

    function unary() {
        if (isOp("-")) { pos++; return -unary(); }
        if (isOp("+")) { pos++; return unary(); }
        return power();
    }

    function power() {
        const base = postfix();
        if (isOp("^")) {
            pos++;
            return Math.pow(base, unary());
        }
        return base;
    }

    function postfix() {
        let v = primary();
        while (isOp("!")) {
            pos++;
            if (v < 0 || v > 170 || !Number.isInteger(v))
                throw new Error("bad factorial");
            let r = 1;
            for (let k = 2; k <= v; k++) r *= k;
            v = r;
        }
        return v;
    }

    function primary() {
        const tok = tokens[pos++];
        if (!tok)
            throw new Error("unexpected end");
        if (tok.t === "num")
            return tok.v;
        if (tok.t === "op" && tok.v === "(") {
            const v = expr();
            if (!isOp(")"))
                throw new Error("missing )");
            pos++;
            return v;
        }
        if (tok.t === "id") {
            if (tok.v in CONSTS)
                return CONSTS[tok.v];
            if (tok.v in FUNCS) {
                if (isOp("(")) {
                    pos++;
                    const arg = expr();
                    if (!isOp(")"))
                        throw new Error("missing )");
                    pos++;
                    return FUNCS[tok.v](arg);
                }
                return FUNCS[tok.v](unary());
            }
        }
        throw new Error("unexpected token");
    }

    const value = expr();
    if (pos !== tokens.length)
        throw new Error("trailing input");
    return value;
}

function looksLikeMath(tokens) {
    if (!tokens || tokens.length < 2)
        return false;
    const hasNum = tokens.some(t => t.t === "num" || (t.t === "id" && t.v in CONSTS));
    const implicitMul = tokens.some((t, i) => t.t === "num" && tokens[i + 1] && (tokens[i + 1].t === "id" || tokens[i + 1].v === "("));
    const hasOp = implicitMul || tokens.some(t => (t.t === "op" && t.v !== "(" && t.v !== ")") || (t.t === "id" && t.v in FUNCS));
    const onlyKnownIds = tokens.every(t => t.t !== "id" || t.v in FUNCS || t.v in CONSTS);
    return hasNum && hasOp && onlyKnownIds;
}

function format(v) {
    if (Number.isInteger(v) && Math.abs(v) < 1e15)
        return v.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    const rounded = parseFloat(v.toPrecision(12));
    if (Math.abs(rounded) >= 1e15 || (Math.abs(rounded) < 1e-6 && rounded !== 0))
        return rounded.toExponential(6).replace(/\.?0+e/, "e");
    const [int, frac] = rounded.toString().split(".");
    return int.replace(/\B(?=(\d{3})+(?!\d))/g, ",") + (frac ? "." + frac : "");
}

function evaluate(src) {
    const expr = src.trim().replace(/^=/, "");
    const tokens = tokenize(expr);
    if (!looksLikeMath(tokens))
        return null;
    try {
        const value = parse(tokens);
        if (typeof value !== "number" || Number.isNaN(value) || !Number.isFinite(value))
            return null;
        const raw = parseFloat(value.toPrecision(15)).toString();
        return { value: raw, display: format(value) };
    } catch (e) {
        return null;
    }
}

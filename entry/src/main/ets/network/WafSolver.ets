export class WafSolver {
  static readonly COOKIE_NAME: string = "acw_sc__v2";
  private static readonly ARG1: RegExp = /var\s+arg1\s*=\s*['"]([0-9A-Fa-f]+)['"]/;
  private static readonly PERMUTATION: number[] = [
    15, 35, 29, 24, 33, 16, 1, 38, 10, 9,
    19, 31, 40, 27, 22, 23, 25, 13, 6, 11,
    39, 18, 20, 8, 14, 21, 32, 26, 2, 30,
    7, 4, 17, 5, 3, 28, 34, 37, 12, 36
  ];
  private static readonly XOR_KEY_HEX: string = "3000176000856006061501533003690027800375";
  private static readonly HEX: string = "0123456789abcdef";

  static looksLikeChallenge(body: string | undefined | null): boolean {
    if (!body) return false;
    if (body.length > 64 * 1024) return false;
    if (body.indexOf(WafSolver.COOKIE_NAME) < 0) return false;
    return WafSolver.ARG1.test(body);
  }

  static solve(body: string | undefined | null): string | undefined {
    if (!body) return undefined;
    const m = WafSolver.ARG1.exec(body);
    if (!m) return undefined;
    const arg1 = m[1];
    let reordered: string = "";
    for (let i = 0; i < WafSolver.PERMUTATION.length; i++) {
      const oneBased = WafSolver.PERMUTATION[i];
      const idx = oneBased - 1;
      if (idx >= 0 && idx < arg1.length) {
        reordered += arg1.charAt(idx);
      }
    }
    const u = reordered;
    let out: string = "";
    const len = Math.min(u.length, WafSolver.XOR_KEY_HEX.length);
    let i = 0;
    while (i + 1 < len) {
      const a = WafSolver.hexVal(u.charAt(i)) * 16 + WafSolver.hexVal(u.charAt(i + 1));
      const b = WafSolver.hexVal(WafSolver.XOR_KEY_HEX.charAt(i)) * 16 + WafSolver.hexVal(WafSolver.XOR_KEY_HEX.charAt(i + 1));
      const v = a ^ b;
      out += WafSolver.HEX.charAt(v >>> 4) + WafSolver.HEX.charAt(v & 0xF);
      i += 2;
    }
    return out;
  }

  private static hexVal(c: string): number {
    const code = c.charCodeAt(0);
    if (code >= 48 && code <= 57) return code - 48;
    if (code >= 97 && code <= 102) return code - 97 + 10;
    if (code >= 65 && code <= 70) return code - 65 + 10;
    return 0;
  }
}

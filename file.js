window.applicationCache.update();

A = 12;
B = 55;
C = 59;
D = 15;

LIMIT = 20;

if (A > LIMIT) {
    document.getElementById("A").innerHTML = "<p style=\"font-size: small\">FL0-FL17:</p><p>HALT</p>";
    document.getElementById("A").className = "HALT";
} else if (A <= LIMIT && A >= 0){
    document.getElementById("A").innerHTML = "<p style=\"font-size: small\">FL0-FL17:</p><p>GO</p>";
    document.getElementById("A").className = "GO";
}

if (B > LIMIT) {
    document.getElementById("B").innerHTML = "<p style=\"font-size: small\">FL17-FL34:</p><p>HALT</p>";
    document.getElementById("B").className = "HALT";
} else if (B <= LIMIT && B >= 0){
    document.getElementById("B").innerHTML = "<p style=\"font-size: small\">FL17-FL34:</p><p>GO</p>";
    document.getElementById("B").className = "GO";
}

if (C > LIMIT) {
    document.getElementById("C").innerHTML = "<p style=\"font-size: small\">FL34-FL51:</p><p>HALT</p>";
    document.getElementById("C").className = "HALT";
} else if (C <= LIMIT && C >= 0){
    document.getElementById("C").innerHTML = "<p style=\"font-size: small\">FL34-FL51:</p><p>GO</p>";
    document.getElementById("C").className = "GO";
}

if (D > LIMIT) {
    document.getElementById("D").innerHTML = "<p style=\"font-size: small\">FL51-FL68:</p><p>HALT</p>";
    document.getElementById("D").className = "HALT";
} else if (D <= LIMIT && D >= 0){
    document.getElementById("D").innerHTML = "<p style=\"font-size: small\">FL51-FL68:</p><p>GO</p>";
    document.getElementById("D").className = "GO";
}

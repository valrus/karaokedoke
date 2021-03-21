var svgNS = "http://www.w3.org/2000/svg";

function getTokenBBox(parentSvg, token) {
    // should probably create text node outside this function and pass in
    var data = document.createTextNode(token);
    var svgElement = document.createElementNS(svgNS, "text");

    svgElement.appendChild(data);
    parentSvg.appendChild(svgElement);
    var bbox = svgElement.getBoundingClientRect();
    parentSvg.removeChild(svgElement);

    return {
        height: bbox.height,
        width: bbox.width
    };
}

function extractDefinedProperty(arr, prop) {
    return arr.map(function(item) {
        return item[prop];
    }).filter(function(item) {
        return item !== undefined;
    });
}

function getSizedLyricPage(pageLyrics, scratchSvgId, font) {
    // console.log(font.unitsPerEm);
    var testSvg = document.getElementById(scratchSvgId);
    var sized_lyric_page = { content: [], size: { height: 0, width: 0 } };
    var this_line = {};
    var this_token = {};
    var line_text = '';
    var line_size = { height: 0, width: 0 };
    for (var line_index = 0; line_index < pageLyrics.lines.length; line_index++) {
        this_line = pageLyrics.lines[line_index];
        line_text = '';
        yMin = yMax = 0;
        for (var token_index = 0; token_index < this_line.tokens.length; token_index++) {
            this_token = this_line.tokens[token_index];
            line_text += " ";
            line_text += this_token.text;
        }
        glyphs = font.stringToGlyphs(line_text);
        yMin = Math.min.apply(null, extractDefinedProperty(glyphs, 'yMin'));
        yMax = Math.max.apply(null, extractDefinedProperty(glyphs, 'yMax'));
        line_size = getTokenBBox(testSvg, line_text);
        sized_lyric_page.content.push({
            content: this_line,
            width: line_size.width,
            yRange: { min: yMin * 512 / font.unitsPerEm, max: yMax * 512 / font.unitsPerEm },
        });
        sized_lyric_page.size.height = sized_lyric_page.size.height + line_size.height;
        sized_lyric_page.size.width = Math.max(sized_lyric_page.size.width, line_size.width);
    }
    return sized_lyric_page;
}

function makeSvgTextElement(font) {
    var svg = document.createElementNS(svgNS, "svg");
    var textElement = document.createElementNS(svgNS, "text");
    var data = document.createTextNode("load this font");
    svg.setAttribute('visibility', 'hidden');
    svg.setAttribute('width', '0');
    svg.setAttribute('height', '0');
    svg.setAttribute('font-family', font);
    svg.setAttribute('font-size', '512px');
    svg.setAttributeNS("http://www.w3.org/2000/xmlns/", "xmlns:xlink", "http://www.w3.org/1999/xlink");

    document.body.appendChild(svg);
    svg.appendChild(textElement);
    textElement.appendChild(data);

    return svg;
}

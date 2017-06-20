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
    console.log(font.unitsPerEm);
    var testSvg = document.getElementById(scratchSvgId);
    var sized_page = [];
    var this_line = {};
    var this_token = {};
    var line_text = '';
    var page_size = {height: 0, width: 0};
    var line_size = {height: 0, width: 0};
    var token_size = {height: 0, width: 0};
    for (var line_index = 0; line_index < pageLyrics.length; line_index++) {
        sized_line = [];
        this_line = pageLyrics[line_index];
        line_text = '';
        yMin = yMax = 0;
        for (var token_index = 0; token_index < this_line.length; token_index++) {
            this_token = this_line[token_index];
            line_text += this_token.text;
            sized_line.push(this_token);
        }
        glyphs = font.stringToGlyphs(line_text);
        console.log(glyphs);
        yMin = Math.min.apply(null, extractDefinedProperty(glyphs, 'yMin'));
        yMax = Math.max.apply(null, extractDefinedProperty(glyphs, 'yMax'));
        line_size = getTokenBBox(testSvg, line_text);
        sized_page.push({
            content: sized_line,
            width: line_size.width,
            y: {min: yMin * 512 / font.unitsPerEm, max: yMax * 512 / font.unitsPerEm},
        });
        page_size.height = page_size.height + line_size.height;
        page_size.width = Math.max(page_size.width, line_size.width);
    }
    return {
        content: sized_page,
        size: page_size
    };
}

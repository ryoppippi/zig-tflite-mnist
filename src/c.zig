pub usingnamespace @cImport({
    @cDefine("STBI_ONLY_PNG", "");
    @cDefine("STB_IMAGE_IMPLEMENTATION", "");
    @cDefine("STB_IMAGE_RESIZE_IMPLEMENTATION", "");
    @cInclude("mallocz.h");
    @cInclude("stb_image.h");
    @cInclude("stb_image_resize.h");
});

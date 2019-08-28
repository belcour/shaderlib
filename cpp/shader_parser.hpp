
// STL includes
#include <string>
#include <fstream>
#include <streambuf>
#include <regex>
#include <iostream>

namespace ShaderLib {

   using ShaderText = std::vector<std::string>;

   /* A ShaderParser enables to load shaders and to look for include files or
    * specify defines during loading.
    */
   class ShaderParser {

      public:
      // Constructor
      ShaderParser(std::string baseUrl = "") : _baseUrl(baseUrl) {

      }

      /* Include shader headers in `src_txt` using library in the search
      * path. This method is asynchronous. Once the shader is parsed and
      * all the includes inlined, it is passed to function `func`.
      */
      std::vector<std::string>
      generateShaderFromFiles (std::vector<std::string> filenames) {

         // For every shader filename in `filenames`, parse the file and
         // add it to the search engine to inline the 
         std::vector<std::string> shaders;
         for(auto filename : filenames)
         {
            ShaderText shader_txt = loadShaderTextFromFile(filename);
            std::string shader = processIncludes(shader_txt);
            shaders.push_back(shader);
         }
         return shaders;
      }

      private:

      /* Load a text file in to a string */
      ShaderText loadShaderTextFromFile(const std::string& filename) const
      {
         ShaderText shader;
         std::ifstream t(filename.c_str());
         while(t)
         {
            std::string line;
            std::getline(t, line);
            shader.push_back(line);
         }
         return shader;
      }
      /* Load a text file in to a string */
      std::string loadTextFromFile(const std::string& filename) const
      {
         std::string shader;
         std::ifstream t(filename.c_str());
         if(t.is_open()) {
            t.seekg(0, std::ios::end);   
            shader.reserve(t.tellg());
            t.seekg(0, std::ios::beg);

            shader.assign((std::istreambuf_iterator<char>(t)),
                           std::istreambuf_iterator<char>());
         } else {
            shader = "<<ERROR: unable to load " + filename + ">>";
         }
         return shader;
      }

      /* Inline every included file found in the global include dictionnary
       * into text buffer `buffer` and return it. Note that the system doesn't
       * catch when a file is included multiple times.
       */
      std::string processIncludes(const ShaderText& buffer)
      {
         std::string shader;
         const std::regex _inlineRegEx("^[ \t]*#include [\"]([^#\"<>\n \t]+)[\"]", std::regex::extended);
         for(auto line : buffer) {
            std::smatch match;
            auto has_match = std::regex_match(line, match, _inlineRegEx);
            if(has_match) {
               std::string include_filename = std::string(match[1].first, match[1].second);
               shader += loadInclude(include_filename);
            } else {
               shader += std::regex_replace(line, _inlineRegEx, "[$1]");
            }
            shader += "\n";
         }
         return shader;
      }

      /* Look in the dictionnary of loaded includes if the filename is present.
       * If not, load the file and store it in the dictionnary. Return the value
       * for the file.
       */
      std::string loadInclude(const std::string& filename)
      {
         if(_everyLoads.count(filename) > 0) {
            return _everyLoads[filename];
         } else {
            _everyLoads[filename] = loadTextFromFile(_baseUrl+filename);
            return _everyLoads[filename];
         }
      }

      /* Global dictionary containing the include files buffers. We load the
       * files included in the shaders and store them inside this dictionnary
       * to finally replace the strings into the shaders.
       */
      std::map<std::string, std::string> _everyLoads;

      std::string _baseUrl;
   };

}

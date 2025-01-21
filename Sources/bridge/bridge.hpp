#ifndef BRIDGE_HPP
#define BRIDGE_HPP

#include <pugixml.hpp>

class bridge_writer : public pugi::xml_writer {
private:
    void (^write_block)(const void*, size_t);

public:
    explicit bridge_writer(void (^block)(const void*, size_t));
    ~bridge_writer();

    void write(const void* data, size_t size) override;
};

void xml_node_print_with_block(
                               const pugi::xml_node& node,
                               const pugi::char_t* indent,
                               unsigned int flags,
                               pugi::xml_encoding encoding,
                               unsigned int depth,
                               void (^block)(const void*, size_t)
                               );

void xml_document_save_with_block(
                                   const pugi::xml_document& node,
                                   const pugi::char_t* indent,
                                   unsigned int flags,
                                   pugi::xml_encoding encoding,
                                   void (^block)(const void*, size_t)
                                   );

pugi::xml_node xml_document_as_node(const pugi::xml_document& node);

#endif // BRIDGE_HPP

// Fixed copy of utils/leaks.cpp for newer glibc: uses __libc_malloc/__libc_free
// directly and a guard so internal allocations don't recurse into the hook.
#include "leaks.hpp"

extern "C" void *__libc_malloc(size_t);
extern "C" void __libc_free(void *);

std::vector<ptr> mallocList;
static bool inHook = false;

bool operator==(ptr const & p1, ptr const & p2)
{
    return (p1.p == p2.p);
}

void * malloc(size_t size) throw()
{
    void * p = __libc_malloc(size);
    if (!inHook)
    {
        inHook = true;
        mallocListAdd(p, size);
        inHook = false;
    }
    return (p);
}

void free(void * p) throw()
{
    __libc_free(p);
    if (!inHook)
    {
        inHook = true;
        mallocListRemove(p);
        inHook = false;
    }
}

void mallocListAdd(void * p, size_t size)
{
    mallocList.push_back(ptr(p, size));
}

void mallocListRemove(void * p)
{
    std::vector<ptr>::iterator it = find(mallocList.begin(), mallocList.end(), ptr(p));
    if (it != mallocList.end())
        mallocList.erase(it);
}

void showLeaks(void)
{
    inHook = true;
    if (mallocList.size() != 0)
    {
        std::ostringstream ss; ss << FG_RED << "LEAKS.KO " << RESET_ALL; write(1, ss.str().c_str(), ss.str().size());
        std::vector<ptr>::iterator it = mallocList.begin(); std::vector<ptr>::iterator ite = mallocList.end();
        for (; it != ite; ++it)
            {std::ostringstream ss; ss << "[" << it->p << " : " << it->size << "] "; write(1, ss.str().c_str(), ss.str().size());}
    }
    mallocList.clear();
    inHook = false;
}

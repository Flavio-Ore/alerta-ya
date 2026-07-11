import { describe, it, expect, vi } from 'vitest';

import { PrismaPanicRepository } from '../prisma-panic.repository';

function makePrismaMock(findManyResult: unknown[], count: number) {
  return {
    panicSession: {
      findMany: vi.fn().mockResolvedValue(findManyResult),
      count: vi.fn().mockResolvedValue(count),
      findUnique: vi.fn(),
    },
  };
}

describe('PrismaPanicRepository.findAllPaginated', () => {
  it('GIVEN page 1 pageSize 20 THEN pide skip 0 take 20 ordenado por startedAt desc', async () => {
    const prisma = makePrismaMock([], 0);
    const repo = new PrismaPanicRepository(prisma as never);

    await repo.findAllPaginated({ page: 1, pageSize: 20 });

    expect(prisma.panicSession.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        skip: 0,
        take: 20,
        orderBy: { startedAt: 'desc' },
        include: { _count: { select: { recordingBlocks: true } } },
      }),
    );
  });

  it('GIVEN page 3 pageSize 10 THEN pide skip 20 take 10', async () => {
    const prisma = makePrismaMock([], 0);
    const repo = new PrismaPanicRepository(prisma as never);

    await repo.findAllPaginated({ page: 3, pageSize: 10 });

    expect(prisma.panicSession.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ skip: 20, take: 10 }),
    );
  });

  it('GIVEN status THEN filtra por status en el where', async () => {
    const prisma = makePrismaMock([], 0);
    const repo = new PrismaPanicRepository(prisma as never);

    await repo.findAllPaginated({ page: 1, pageSize: 20, status: 'DEACTIVATED' });

    expect(prisma.panicSession.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { status: 'DEACTIVATED' } }),
    );
  });

  it('GIVEN sin status THEN where vacío (trae todos los status)', async () => {
    const prisma = makePrismaMock([], 0);
    const repo = new PrismaPanicRepository(prisma as never);

    await repo.findAllPaginated({ page: 1, pageSize: 20 });

    expect(prisma.panicSession.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: {} }),
    );
  });

  it('THEN devuelve items + total del count()', async () => {
    const session = { id: 's1', lat: 1, lng: 2, startedAt: new Date(), endedAt: null, status: 'ACTIVE', deactivatedBy: null, _count: { recordingBlocks: 3 } };
    const prisma = makePrismaMock([session], 42);
    const repo = new PrismaPanicRepository(prisma as never);

    const result = await repo.findAllPaginated({ page: 1, pageSize: 20 });

    expect(result.total).toBe(42);
    expect(result.items).toEqual([session]);
  });
});

describe('PrismaPanicRepository.findByIdWithCount', () => {
  it('THEN pide findUnique con include _count.recordingBlocks', async () => {
    const prisma = makePrismaMock([], 0);
    const repo = new PrismaPanicRepository(prisma as never);

    await repo.findByIdWithCount('ses-1');

    expect(prisma.panicSession.findUnique).toHaveBeenCalledWith({
      where: { id: 'ses-1' },
      include: { _count: { select: { recordingBlocks: true } } },
    });
  });

  it('GIVEN sesión inexistente THEN devuelve null', async () => {
    const prisma = makePrismaMock([], 0);
    prisma.panicSession.findUnique.mockResolvedValue(null);
    const repo = new PrismaPanicRepository(prisma as never);

    const result = await repo.findByIdWithCount('ses-404');

    expect(result).toBeNull();
  });
});
